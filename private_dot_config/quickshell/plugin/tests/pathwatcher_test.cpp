#include "pathwatcher.hpp"

#include <QDir>
#include <QElapsedTimer>
#include <QFile>
#include <QFileInfo>
#include <QSignalSpy>
#include <QTemporaryDir>
#include <QtTest/QTest>

#include <fcntl.h>
#include <sys/inotify.h>
#include <unistd.h>

#include <chrono>
#include <cstddef>
#include <cstring>
#include <string>
#include <vector>

using namespace std::chrono_literals;

namespace {

struct DecodedEvent {
  int wd;
  std::uint32_t mask;
  std::string name;

  friend bool operator==(const DecodedEvent &, const DecodedEvent &) = default;
};

void appendEvent(std::vector<std::byte> &buffer, int wd, std::uint32_t mask,
                 const std::string &name, std::uint32_t paddedLength) {
  inotify_event header{};
  header.wd = wd;
  header.mask = mask;
  header.len = paddedLength;
  const auto offset = buffer.size();
  buffer.resize(offset + sizeof header + paddedLength);
  std::memcpy(buffer.data() + offset, &header, sizeof header);
  std::memcpy(buffer.data() + offset + sizeof header, name.data(), name.size());
}

std::vector<DecodedEvent> decode(std::span<const std::byte> buffer) {
  std::vector<DecodedEvent> events;
  forEachInotifyEvent(buffer, [&](const InotifyEvent &event) {
    events.push_back({event.wd, event.mask, std::string(event.name)});
  });
  return events;
}

class Tree {
public:
  Tree()
      : m_root(QFile::encodeName(QFileInfo(m_dir.path()).canonicalFilePath())
                   .toStdString()) {}

  [[nodiscard]] std::string path(const std::string &relative) const {
    return m_root + "/" + relative;
  }

  [[nodiscard]] std::string store() const { return path("store"); }

  void mkdir(const std::string &relative) const {
    QDir().mkpath(QFile::decodeName(QByteArray::fromStdString(path(relative))));
  }

  void write(const std::string &relative, const char *contents = "x") const {
    const int fd = ::open(path(relative).c_str(),
                          O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC, 0644);
    if (fd < 0 || ::write(fd, contents, std::strlen(contents)) < 0)
      qFatal("cannot write %s", relative.c_str());
    ::close(fd);
  }

  void remove(const std::string &relative) const {
    ::unlink(path(relative).c_str());
  }

  void rmdir(const std::string &relative) const {
    ::rmdir(path(relative).c_str());
  }

  void rename(const std::string &from, const std::string &to) const {
    if (::rename(path(from).c_str(), path(to).c_str()) != 0)
      qFatal("cannot rename %s", from.c_str());
  }

  void link(const std::string &target, const std::string &relative) const {
    if (::symlink(target.c_str(), path(relative).c_str()) != 0)
      qFatal("cannot link %s", relative.c_str());
  }

  void swapLink(const std::string &target, const std::string &relative) const {
    link(target, relative + ".tmp");
    rename(relative + ".tmp", relative);
  }

private:
  QTemporaryDir m_dir;
  std::string m_root;
};

PathWatcher::Resolver resolverFor(const Tree &tree) {
  return [store = tree.store()](std::span<const std::string> paths) {
    return resolveWatchPoints(paths, store);
  };
}

constexpr PathWatcher::Timing FAST{.quiet = 10ms, .maxWait = 100ms};

void settle() { QTest::qWait(250); }

} // namespace

class PathWatcherTest : public QObject {
  Q_OBJECT

private slots:
  void decodesEveryEventInBuffer();
  void stopsAtTruncatedEvent();
  void renameSwapOfLinkEmitsOnce();
  void unlinkThenRelinkEmitsOnce();
  void siblingChurnBesideLinkEmitsNothing();
  void burstEmitsOnce();
  void steadyStreamEmitsAtBoundedRate();
  void desktopFileInContentsEmits();
  void otherFileInContentsEmitsNothing();
  void inPlaceEditOfDesktopFileEmits();
  void removedContentsDirectoryEmitsOnce();
  void movedAnchorDirectoryEmits();
  void anchorAndContentsOnSameDirectoryKeepBothMasks();
  void watchingSameSetTwiceKeepsEventsWithoutSpuriousChange();
  void missingChainEmitsAtEveryStep();
  void eventInsideChangedHandlerEmitsExactlyOnceMore();
  void retargetDuringApplyIsPickedUp();
  void idleWatcherHasNoActiveTimer();
};

void PathWatcherTest::decodesEveryEventInBuffer() {
  std::vector<std::byte> buffer;
  appendEvent(buffer, 3, IN_CREATE, "static", 16);
  appendEvent(buffer, 4, IN_ATTRIB, "", 0);
  appendEvent(buffer, -1, IN_Q_OVERFLOW, "", 0);
  appendEvent(buffer, 5, IN_MOVED_TO | IN_ISDIR, "current-system", 32);

  QCOMPARE(decode(buffer),
           std::vector<DecodedEvent>({
               {3, IN_CREATE, "static"},
               {4, IN_ATTRIB, ""},
               {-1, IN_Q_OVERFLOW, ""},
               {5, IN_MOVED_TO | IN_ISDIR, "current-system"},
           }));
}

void PathWatcherTest::stopsAtTruncatedEvent() {
  std::vector<std::byte> buffer;
  appendEvent(buffer, 7, IN_CREATE, "complete", 16);
  appendEvent(buffer, 8, IN_CREATE, "truncated-name", 32);
  buffer.resize(buffer.size() - 24);

  QCOMPARE(decode(buffer), std::vector<DecodedEvent>({
                               {7, IN_CREATE, "complete"},
                               {8, IN_CREATE, "truncate"},
                           }));
}

void PathWatcherTest::renameSwapOfLinkEmitsOnce() {
  Tree tree;
  tree.mkdir("store/gen-1/applications");
  tree.mkdir("store/gen-2/applications");
  tree.mkdir("run");
  tree.link(tree.path("store/gen-1"), "run/current-system");
  PathWatcher watcher(resolverFor(tree), FAST);
  QSignalSpy changed(&watcher, &PathWatcher::changed);
  watcher.watch({{tree.path("run/current-system/applications")}}, ".desktop");

  tree.swapLink(tree.path("store/gen-2"), "run/current-system");

  QTRY_COMPARE(changed.count(), 1);
  settle();
  QCOMPARE(changed.count(), 1);
}

void PathWatcherTest::unlinkThenRelinkEmitsOnce() {
  Tree tree;
  tree.mkdir("store/gen-1/applications");
  tree.mkdir("store/gen-2/applications");
  tree.mkdir("run");
  tree.link(tree.path("store/gen-1"), "run/current-system");
  PathWatcher watcher(resolverFor(tree), FAST);
  QSignalSpy changed(&watcher, &PathWatcher::changed);
  watcher.watch({{tree.path("run/current-system/applications")}}, ".desktop");

  tree.remove("run/current-system");
  tree.link(tree.path("store/gen-2"), "run/current-system");

  QTRY_COMPARE(changed.count(), 1);
  settle();
  QCOMPARE(changed.count(), 1);
}

void PathWatcherTest::siblingChurnBesideLinkEmitsNothing() {
  Tree tree;
  tree.mkdir("store/profile/applications");
  tree.mkdir("home");
  tree.link(tree.path("store/profile"), "home/.nix-profile");
  PathWatcher watcher(resolverFor(tree), FAST);
  QSignalSpy changed(&watcher, &PathWatcher::changed);
  watcher.watch({{tree.path("home/.nix-profile/applications")}}, ".desktop");

  for (int i = 0; i < 50; ++i) {
    tree.write("home/.claude.json.tmp");
    tree.rename("home/.claude.json.tmp", "home/.claude.json");
  }
  tree.remove("home/.claude.json");

  settle();
  QCOMPARE(changed.count(), 0);
}

void PathWatcherTest::burstEmitsOnce() {
  Tree tree;
  tree.mkdir("home/applications");
  PathWatcher watcher(resolverFor(tree), FAST);
  QSignalSpy changed(&watcher, &PathWatcher::changed);
  watcher.watch({{tree.path("home/applications")}}, ".desktop");

  for (int i = 0; i < 500; ++i)
    tree.write("home/applications/app-" + std::to_string(i) + ".desktop");

  QTRY_COMPARE(changed.count(), 1);
  settle();
  QCOMPARE(changed.count(), 1);
}

void PathWatcherTest::steadyStreamEmitsAtBoundedRate() {
  Tree tree;
  tree.mkdir("home/applications");
  PathWatcher watcher(resolverFor(tree), {.quiet = 60ms, .maxWait = 200ms});
  QSignalSpy changed(&watcher, &PathWatcher::changed);
  watcher.watch({{tree.path("home/applications")}}, ".desktop");

  QElapsedTimer clock;
  clock.start();
  qint64 firstEmission = -1;
  for (int i = 0; clock.elapsed() < 700; ++i) {
    tree.write("home/applications/stream-" + std::to_string(i) + ".desktop");
    QTest::qWait(20);
    if (firstEmission < 0 && changed.count() > 0)
      firstEmission = clock.elapsed();
  }

  QCOMPARE_GE(firstEmission, 150);
  QCOMPARE_LE(firstEmission, 320);
  QCOMPARE_GE(changed.count(), 2);
  QCOMPARE_LE(changed.count(), 4);
}

void PathWatcherTest::desktopFileInContentsEmits() {
  Tree tree;
  tree.mkdir("home/applications");
  PathWatcher watcher(resolverFor(tree), FAST);
  QSignalSpy changed(&watcher, &PathWatcher::changed);
  watcher.watch({{tree.path("home/applications")}}, ".desktop");

  tree.write("home/applications/steam.desktop");

  QTRY_COMPARE(changed.count(), 1);
}

void PathWatcherTest::otherFileInContentsEmitsNothing() {
  Tree tree;
  tree.mkdir("home/applications");
  PathWatcher watcher(resolverFor(tree), FAST);
  QSignalSpy changed(&watcher, &PathWatcher::changed);
  watcher.watch({{tree.path("home/applications")}}, ".desktop");

  tree.write("home/applications/notes.txt");
  tree.write("home/applications/mimeinfo.cache");

  settle();
  QCOMPARE(changed.count(), 0);
}

void PathWatcherTest::inPlaceEditOfDesktopFileEmits() {
  Tree tree;
  tree.mkdir("home/applications");
  tree.write("home/applications/editor.desktop");
  PathWatcher watcher(resolverFor(tree), FAST);
  QSignalSpy changed(&watcher, &PathWatcher::changed);
  watcher.watch({{tree.path("home/applications")}}, ".desktop");

  const int fd = ::open(tree.path("home/applications/editor.desktop").c_str(),
                        O_WRONLY | O_APPEND | O_CLOEXEC);
  QCOMPARE_GE(::write(fd, "NoDisplay=true\n", 15), 15);
  ::close(fd);

  QTRY_COMPARE(changed.count(), 1);
}

void PathWatcherTest::removedContentsDirectoryEmitsOnce() {
  Tree tree;
  tree.mkdir("home/applications");
  PathWatcher watcher(resolverFor(tree), FAST);
  QSignalSpy changed(&watcher, &PathWatcher::changed);
  watcher.watch({{tree.path("home/applications")}}, ".desktop");

  tree.rmdir("home/applications");

  QTRY_COMPARE(changed.count(), 1);
  settle();
  QCOMPARE(changed.count(), 1);
}

void PathWatcherTest::movedAnchorDirectoryEmits() {
  Tree tree;
  tree.mkdir("state/nix");
  PathWatcher watcher(resolverFor(tree), FAST);
  QSignalSpy changed(&watcher, &PathWatcher::changed);
  watcher.watch({{tree.path("state/nix/profile/applications")}}, ".desktop");

  tree.rename("state/nix", "state/nix-old");

  QTRY_COMPARE(changed.count(), 1);
}

void PathWatcherTest::anchorAndContentsOnSameDirectoryKeepBothMasks() {
  Tree tree;
  tree.mkdir("home/applications");
  tree.write("home/applications/editor.desktop");
  PathWatcher watcher(resolverFor(tree), FAST);
  QSignalSpy changed(&watcher, &PathWatcher::changed);
  watcher.watch({{tree.path("home/applications"),
                  tree.path("home/applications/missing/applications")}},
                ".desktop");

  const int fd = ::open(tree.path("home/applications/editor.desktop").c_str(),
                        O_WRONLY | O_APPEND | O_CLOEXEC);
  QCOMPARE_GE(::write(fd, "x", 1), 1);
  ::close(fd);
  QTRY_COMPARE(changed.count(), 1);

  tree.write("home/applications/missing");
  QTRY_COMPARE(changed.count(), 2);
}

void PathWatcherTest::watchingSameSetTwiceKeepsEventsWithoutSpuriousChange() {
  Tree tree;
  tree.mkdir("store/gen-1/applications");
  tree.mkdir("store/gen-2/applications");
  tree.mkdir("run");
  tree.mkdir("home/applications");
  tree.link(tree.path("store/gen-1"), "run/current-system");
  const std::vector<std::string> paths = {
      tree.path("home/applications"),
      tree.path("run/current-system/applications")};
  PathWatcher watcher(resolverFor(tree), FAST);
  QSignalSpy changed(&watcher, &PathWatcher::changed);

  watcher.watch(paths, ".desktop");
  watcher.watch(paths, ".desktop");
  settle();
  QCOMPARE(changed.count(), 0);

  tree.swapLink(tree.path("store/gen-2"), "run/current-system");
  QTRY_COMPARE(changed.count(), 1);
}

void PathWatcherTest::missingChainEmitsAtEveryStep() {
  Tree tree;
  tree.mkdir("base");
  const std::vector<std::string> paths = {tree.path("base/a/b/applications")};
  PathWatcher watcher(resolverFor(tree), FAST);
  QSignalSpy changed(&watcher, &PathWatcher::changed);
  connect(&watcher, &PathWatcher::changed, &watcher,
          [&] { watcher.watch(paths, ".desktop"); });
  watcher.watch(paths, ".desktop");

  tree.mkdir("base/a");
  QTRY_COMPARE(changed.count(), 1);
  tree.mkdir("base/a/b");
  QTRY_COMPARE(changed.count(), 2);
  tree.mkdir("base/a/b/applications");
  QTRY_COMPARE(changed.count(), 3);
  tree.write("base/a/b/applications/new.desktop");
  QTRY_COMPARE(changed.count(), 4);
}

void PathWatcherTest::eventInsideChangedHandlerEmitsExactlyOnceMore() {
  Tree tree;
  tree.mkdir("home/applications");
  const std::vector<std::string> paths = {tree.path("home/applications")};
  PathWatcher watcher(resolverFor(tree), FAST);
  QSignalSpy changed(&watcher, &PathWatcher::changed);
  bool wroteFromHandler = false;
  connect(&watcher, &PathWatcher::changed, &watcher, [&] {
    watcher.watch(paths, ".desktop");
    if (!wroteFromHandler) {
      wroteFromHandler = true;
      tree.write("home/applications/second.desktop");
    }
  });
  watcher.watch(paths, ".desktop");

  tree.write("home/applications/first.desktop");

  QTRY_COMPARE(changed.count(), 2);
  settle();
  QCOMPARE(changed.count(), 2);
}

void PathWatcherTest::retargetDuringApplyIsPickedUp() {
  Tree tree;
  tree.mkdir("store/gen-1/applications");
  tree.mkdir("store/gen-2/applications");
  tree.mkdir("store/gen-3/applications");
  tree.mkdir("run");
  tree.link(tree.path("store/gen-1"), "run/current-system");
  tree.link(tree.path("store/gen-2"), "run/next");

  int resolveCount = 0;
  PathWatcher watcher(
      [&](std::span<const std::string> paths) {
        auto points = resolveWatchPoints(paths, tree.store());
        if (++resolveCount == 1)
          tree.swapLink(tree.path("run/next"), "run/current-system");
        return points;
      },
      FAST);
  QSignalSpy changed(&watcher, &PathWatcher::changed);
  watcher.watch({{tree.path("run/current-system/applications")}}, ".desktop");
  settle();
  changed.clear();

  tree.swapLink(tree.path("store/gen-3"), "run/next");

  QTRY_COMPARE(changed.count(), 1);
}

void PathWatcherTest::idleWatcherHasNoActiveTimer() {
  Tree tree;
  tree.mkdir("home/applications");
  PathWatcher watcher(resolverFor(tree), FAST);
  watcher.watch({{tree.path("home/applications")}}, ".desktop");

  settle();

  QCOMPARE(watcher.m_timer.isActive(), false);
  QCOMPARE(watcher.m_burstPending, false);
}

QTEST_GUILESS_MAIN(PathWatcherTest)
#include "pathwatcher_test.moc"
