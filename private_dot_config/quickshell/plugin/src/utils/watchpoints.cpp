#include "watchpoints.hpp"

#include <dirent.h>
#include <sys/stat.h>
#include <unistd.h>

#include <algorithm>
#include <array>
#include <cerrno>
#include <climits>
#include <memory>
#include <utility>

namespace {

constexpr int MAX_LINK_HOPS = 40;
constexpr int MAX_SUBDIRECTORY_DEPTH = 8;

struct DirCloser {
  void operator()(DIR *dir) const { ::closedir(dir); }
};
using DirHandle = std::unique_ptr<DIR, DirCloser>;

struct DirIdentity {
  dev_t device;
  ino_t inode;

  friend bool operator==(const DirIdentity &, const DirIdentity &) = default;
};

bool isDirectoryEntry(DIR *dir, const dirent &entry) {
  if (entry.d_type == DT_DIR)
    return true;
  if (entry.d_type != DT_LNK && entry.d_type != DT_UNKNOWN)
    return false;
  struct stat target{};
  return ::fstatat(::dirfd(dir), entry.d_name, &target, 0) == 0 &&
         S_ISDIR(target.st_mode);
}

class Walk {
public:
  Walk(std::string_view immutableRoot, std::vector<WatchPoint> &points)
      : m_immutableRoot(immutableRoot), m_points(points) {}

  void resolveTree(std::string_view path) {
    resolve(path, 0);
    while (!m_subdirectories.empty()) {
      auto [subdirectory, depth] = std::move(m_subdirectories.back());
      m_subdirectories.pop_back();
      resolve(subdirectory, depth);
    }
  }

private:
  void resolve(std::string_view path, int depth) {
    if (!path.starts_with('/'))
      return;
    m_current.clear();
    m_pending.clear();
    pushComponents(path);

    int hops = 0;
    while (!m_pending.empty()) {
      const std::string component = std::move(m_pending.back());
      m_pending.pop_back();
      if (component == "..") {
        popComponent();
        continue;
      }

      const std::string parent = currentPath();
      const std::string candidate = m_current + "/" + component;
      struct stat status{};
      if (::lstat(candidate.c_str(), &status) != 0) {
        if (errno == ENOENT || errno == ENOTDIR)
          anchor({AnchorKind::Missing, parent, component}, parent);
        return;
      }

      if (S_ISLNK(status.st_mode)) {
        anchor({AnchorKind::Link, candidate, {}}, parent);
        if (++hops > MAX_LINK_HOPS || !followLink(candidate))
          return;
        continue;
      }

      if (!S_ISDIR(status.st_mode)) {
        anchor({AnchorKind::Missing, parent, component}, parent);
        return;
      }
      m_current = candidate;
    }

    const std::string directory = currentPath();
    if (isImmutable(directory))
      return;
    m_points.push_back({AnchorKind::Contents, directory, {}});
    if (depth < MAX_SUBDIRECTORY_DEPTH)
      queueSubdirectories(directory, depth + 1);
  }

  void queueSubdirectories(const std::string &directory, int depth) {
    const DirHandle dir(::opendir(directory.c_str()));
    if (!dir || !markVisited(dir.get()))
      return;
    while (const dirent *entry = ::readdir(dir.get())) {
      if (entry->d_name[0] != '.' && isDirectoryEntry(dir.get(), *entry))
        m_subdirectories.emplace_back(directory + "/" + entry->d_name, depth);
    }
  }

  bool markVisited(DIR *dir) {
    struct stat status{};
    if (::fstat(::dirfd(dir), &status) != 0)
      return false;
    const DirIdentity identity{status.st_dev, status.st_ino};
    if (std::ranges::find(m_visited, identity) != m_visited.end())
      return false;
    m_visited.push_back(identity);
    return true;
  }

  [[nodiscard]] std::string currentPath() const {
    return m_current.empty() ? std::string("/") : m_current;
  }

  [[nodiscard]] bool isImmutable(std::string_view directory) const {
    if (m_immutableRoot.empty() || !directory.starts_with(m_immutableRoot))
      return false;
    return directory.size() == m_immutableRoot.size() ||
           directory[m_immutableRoot.size()] == '/';
  }

  void anchor(WatchPoint point, std::string_view location) {
    if (!isImmutable(location))
      m_points.push_back(std::move(point));
  }

  void popComponent() {
    const auto slash = m_current.rfind('/');
    m_current.erase(slash == std::string::npos ? 0 : slash);
  }

  void pushComponents(std::string_view path) {
    std::vector<std::string> components;
    while (!path.empty()) {
      const auto slash = path.find('/');
      const auto component = path.substr(0, slash);
      if (!component.empty() && component != ".")
        components.emplace_back(component);
      if (slash == std::string_view::npos)
        break;
      path.remove_prefix(slash + 1);
    }
    m_pending.insert(m_pending.end(), components.rbegin(), components.rend());
  }

  bool followLink(const std::string &link) {
    std::array<char, PATH_MAX> target{};
    const auto length = ::readlink(link.c_str(), target.data(), target.size());
    if (length <= 0 || static_cast<std::size_t>(length) == target.size())
      return false;
    const std::string_view targetPath(target.data(),
                                      static_cast<std::size_t>(length));
    if (targetPath.starts_with('/'))
      m_current.clear();
    pushComponents(targetPath);
    return true;
  }

  std::string_view m_immutableRoot;
  std::vector<WatchPoint> &m_points;
  std::string m_current;
  std::vector<std::string> m_pending;
  std::vector<std::pair<std::string, int>> m_subdirectories;
  std::vector<DirIdentity> m_visited;
};

} // namespace

std::vector<WatchPoint> resolveWatchPoints(std::span<const std::string> paths,
                                           std::string_view immutableRoot) {
  std::vector<WatchPoint> points;
  Walk walk(immutableRoot, points);
  for (const auto &path : paths)
    walk.resolveTree(path);
  std::ranges::sort(points);
  const auto duplicates = std::ranges::unique(points);
  points.erase(duplicates.begin(), duplicates.end());
  return points;
}
