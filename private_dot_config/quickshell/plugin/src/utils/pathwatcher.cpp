#include "pathwatcher.hpp"

#include <QDebug>

#include <unistd.h>

#include <array>
#include <cerrno>
#include <system_error>
#include <utility>

namespace {

class UnhandledAnchorKindError : public std::logic_error {
public:
  using std::logic_error::logic_error;
};

constexpr int MAX_SETTLE_ROUNDS = 3;
constexpr std::size_t READ_BUFFER_SIZE = 4096;

constexpr std::uint32_t LINK_MASK =
    IN_ATTRIB | IN_DELETE_SELF | IN_MOVE_SELF | IN_DONT_FOLLOW;
constexpr std::uint32_t MISSING_MASK = IN_CREATE | IN_MOVED_TO |
                                       IN_DELETE_SELF | IN_MOVE_SELF |
                                       IN_ONLYDIR | IN_DONT_FOLLOW;
constexpr std::uint32_t CONTENTS_MASK =
    IN_CREATE | IN_DELETE | IN_MOVED_FROM | IN_MOVED_TO | IN_CLOSE_WRITE |
    IN_DELETE_SELF | IN_MOVE_SELF | IN_ONLYDIR | IN_DONT_FOLLOW |
    IN_EXCL_UNLINK;

std::uint32_t maskFor(AnchorKind kind) {
  switch (kind) {
  case AnchorKind::Link:
    return LINK_MASK;
  case AnchorKind::Missing:
    return MISSING_MASK;
  case AnchorKind::Contents:
    return CONTENTS_MASK;
  }
  throw UnhandledAnchorKindError("unhandled AnchorKind " +
                         std::to_string(static_cast<int>(kind)));
}

struct Group {
  std::string path;
  std::uint32_t mask{0};
  bool link{false};
  bool contents{false};
  std::vector<std::string> entries;
};

std::vector<Group> groupByPath(const std::vector<WatchPoint> &points) {
  std::vector<Group> groups;
  for (const auto &point : points) {
    auto group = std::ranges::find(groups, point.path, &Group::path);
    if (group == groups.end()) {
      groups.push_back({.path = point.path,
                        .mask = 0,
                        .link = false,
                        .contents = false,
                        .entries = {}});
      group = std::prev(groups.end());
    }
    group->mask |= maskFor(point.kind);
    group->link = group->link || point.kind == AnchorKind::Link;
    group->contents = group->contents || point.kind == AnchorKind::Contents;
    if (!point.entry.empty())
      group->entries.push_back(point.entry);
  }
  return groups;
}

bool isRaceError(int error) { return error == ENOENT || error == ENOTDIR; }

bool isPermanentError(int error) {
  return error == EACCES || error == EPERM || error == ELOOP ||
         error == ENAMETOOLONG;
}

std::string describe(int error) {
  return std::generic_category().message(error);
}

} // namespace

PathWatcher::PathWatcher(Resolver resolver, Timing timing, QObject *parent)
    : QObject(parent), m_resolver(std::move(resolver)), m_timing(timing),
      m_notifier(QSocketNotifier::Read) {
  m_timer.setSingleShot(true);
  connect(&m_timer, &QTimer::timeout, this, &PathWatcher::flush);
  connect(&m_notifier, &QSocketNotifier::activated, this,
          [this] { readEvents(true); });
}

void PathWatcher::watch(std::span<const std::string> paths,
                        std::string_view contentSuffix) {
  ensureInotify();
  m_contentSuffix = contentSuffix;

  auto points = m_resolver(paths);
  for (int round = 0; round < MAX_SETTLE_ROUNDS; ++round) {
    auto next = apply(points);
    removeStaleWatches(next);
    m_watches = std::move(next);

    auto resolvedAgain = m_resolver(paths);
    if (resolvedAgain == points)
      return;
    points = std::move(resolvedAgain);
  }
  arm();
}

void PathWatcher::ensureInotify() {
  if (m_fd)
    return;
  const int fd = ::inotify_init1(IN_NONBLOCK | IN_CLOEXEC);
  if (fd < 0)
    throw InotifyInitError("inotify_init1 failed: " + describe(errno));
  m_fd.reset(fd);
  m_watches.clear();
  m_notifier.setSocket(fd);
  m_notifier.setEnabled(true);
}

std::vector<PathWatcher::Watch>
PathWatcher::apply(const std::vector<WatchPoint> &points) {
  std::vector<Watch> next;
  bool raced = false;
  for (auto &group : groupByPath(points)) {
    const int wd =
        ::inotify_add_watch(m_fd.get(), group.path.c_str(), group.mask);
    if (wd < 0) {
      const int error = errno;
      if (error == ENOSPC)
        throw WatchLimitError("inotify watch limit reached at " + group.path);
      if (isRaceError(error)) {
        raced = true;
        continue;
      }
      if (isPermanentError(error)) {
        warnOnce(group.path, error);
        continue;
      }
      throw PathWatchError("inotify_add_watch " + group.path + ": " +
                           describe(error));
    }

    auto existing = std::ranges::find(next, wd, &Watch::wd);
    if (existing == next.end()) {
      next.push_back({.wd = wd,
                      .mask = group.mask,
                      .link = group.link,
                      .contents = group.contents,
                      .entries = std::move(group.entries)});
      continue;
    }
    existing->mask |= group.mask;
    existing->link = existing->link || group.link;
    existing->contents = existing->contents || group.contents;
    existing->entries.insert(existing->entries.end(), group.entries.begin(),
                             group.entries.end());
    if (::inotify_add_watch(m_fd.get(), group.path.c_str(), existing->mask) < 0)
      raced = true;
  }
  if (raced)
    arm();
  return next;
}

void PathWatcher::removeStaleWatches(const std::vector<Watch> &next) const {
  for (const auto &watch : m_watches) {
    if (std::ranges::find(next, watch.wd, &Watch::wd) == next.end())
      ::inotify_rm_watch(m_fd.get(), watch.wd);
  }
}

void PathWatcher::readEvents(bool armOnRelevant) {
  std::array<std::byte, READ_BUFFER_SIZE> buffer{};
  while (m_fd) {
    const auto count = ::read(m_fd.get(), buffer.data(), buffer.size());
    if (count < 0 && errno == EINTR)
      continue;
    if (count < 0 && errno == EAGAIN)
      return;
    if (count <= 0) {
      qWarning() << "[PathWatcher] reading inotify events failed:"
                 << describe(errno).c_str();
      m_notifier.setEnabled(false);
      m_fd.reset();
      m_watches.clear();
      arm();
      return;
    }

    bool relevant = false;
    forEachInotifyEvent(
        std::span(buffer.data(), static_cast<std::size_t>(count)),
        [&](const InotifyEvent &event) {
          if (handleEvent(event))
            relevant = true;
        });
    if (relevant && armOnRelevant)
      arm();
  }
}

bool PathWatcher::handleEvent(const InotifyEvent &event) {
  if (event.mask & IN_Q_OVERFLOW)
    return true;

  const auto watch = std::ranges::find(m_watches, event.wd, &Watch::wd);
  if (watch == m_watches.end())
    return false;
  if (event.mask & IN_IGNORED) {
    m_watches.erase(watch);
    return true;
  }
  if (watch->link || (event.mask & (IN_DELETE_SELF | IN_MOVE_SELF)))
    return true;
  if (event.name.empty())
    return false;
  if (std::ranges::find(watch->entries, event.name) != watch->entries.end())
    return true;
  return watch->contents && ((event.mask & IN_ISDIR) ||
                             event.name.ends_with(m_contentSuffix));
}

void PathWatcher::warnOnce(const std::string &path, int error) {
  if (std::ranges::find(m_warnedPaths, path) != m_warnedPaths.end())
    return;
  m_warnedPaths.push_back(path);
  qWarning() << "[PathWatcher] cannot watch" << path.c_str() << ":"
             << describe(error).c_str();
}

void PathWatcher::arm() {
  if (!m_burstPending) {
    m_burstPending = true;
    m_burstClock.start();
  }
  const auto elapsed = std::chrono::milliseconds(m_burstClock.elapsed());
  const auto remaining =
      std::max(std::chrono::milliseconds::zero(), m_timing.maxWait - elapsed);
  m_timer.start(std::min(m_timing.quiet, remaining));
}

void PathWatcher::flush() {
  m_burstPending = false;
  if (m_fd)
    readEvents(false);
  emit changed();
}
