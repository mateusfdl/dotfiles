#include "watchpoints.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QTemporaryDir>
#include <QtTest/QTest>

#include <sys/stat.h>
#include <unistd.h>

#include <algorithm>
#include <string>
#include <vector>

namespace QTest {

template <> char *toString(const std::vector<WatchPoint> &points) {
  QString text;
  for (const auto &point : points) {
    const char *kind = point.kind == AnchorKind::Link      ? "Link"
                       : point.kind == AnchorKind::Missing ? "Missing"
                                                           : "Contents";
    text += QStringLiteral("%1{%2, %3}\n")
                .arg(QLatin1String(kind), QString::fromStdString(point.path),
                     QString::fromStdString(point.entry));
  }
  return qstrdup(text.toUtf8().constData());
}

} // namespace QTest

namespace {

class Tree {
public:
  Tree()
      : m_root(QFile::encodeName(QFileInfo(m_dir.path()).canonicalFilePath())
                   .toStdString()) {}

  [[nodiscard]] std::string path(const std::string &relative) const {
    return relative.empty() ? m_root : m_root + "/" + relative;
  }

  [[nodiscard]] std::string store() const { return path("store"); }

  void mkdir(const std::string &relative) const {
    QDir().mkpath(QFile::decodeName(QByteArray::fromStdString(path(relative))));
  }

  void file(const std::string &relative) const {
    QFile output(QFile::decodeName(QByteArray::fromStdString(path(relative))));
    if (!output.open(QIODevice::WriteOnly))
      qFatal("cannot create %s", relative.c_str());
  }

  void link(const std::string &target, const std::string &relative) const {
    if (::symlink(target.c_str(), path(relative).c_str()) != 0)
      qFatal("cannot link %s", relative.c_str());
  }

private:
  QTemporaryDir m_dir;
  std::string m_root;
};

std::vector<WatchPoint> sorted(std::vector<WatchPoint> points) {
  std::ranges::sort(points);
  return points;
}

WatchPoint linkAt(const std::string &path) {
  return {AnchorKind::Link, path, {}};
}

WatchPoint missing(const std::string &parent, const std::string &entry) {
  return {AnchorKind::Missing, parent, entry};
}

WatchPoint contents(const std::string &path) {
  return {AnchorKind::Contents, path, {}};
}

std::vector<WatchPoint> resolve(const Tree &tree,
                                std::vector<std::string> paths) {
  return resolveWatchPoints(paths, tree.store());
}

} // namespace

class WatchPointsTest : public QObject {
  Q_OBJECT

private slots:
  void plainDirectoryIsWatchedForContents();
  void relativeLinkChainIsAnchoredAtEveryWritableLink();
  void absoluteTargetRestartsAtRoot();
  void dotDotAfterLinkResolvesPhysically();
  void linkLoopStopsAtHopBudget();
  void danglingChainAnchorsTheFirstMissingTarget();
  void onlyFirstMissingComponentIsAnchored();
  void fileWhereDirectoryIsExpectedIsAnchoredAsMissing();
  void redundantSeparatorsAndDotsAreIgnored();
  void relativePathsAreRejected();
  void unreadableDirectoryIsSkipped();
  void immutableRegionHasNoAnchors();
  void immutableLinkBackIntoWritableDirectoryResumesAnchoring();
  void immutableRootMatchesWholeComponentsOnly();
  void sharedAnchorsAreDeduplicated();
  void subdirectoriesOfWritableContentsAreWatched();
  void subdirectoryLinkIsAnchoredAndFollowed();
  void subdirectoryLinkLoopTerminates();
};

void WatchPointsTest::plainDirectoryIsWatchedForContents() {
  Tree tree;
  tree.mkdir("home/applications");

  QCOMPARE(resolve(tree, {tree.path("home/applications")}),
           std::vector<WatchPoint>({contents(tree.path("home/applications"))}));
}

void WatchPointsTest::relativeLinkChainIsAnchoredAtEveryWritableLink() {
  Tree tree;
  tree.mkdir("store/profile-a/share/applications");
  tree.mkdir("profiles");
  tree.link(tree.path("store/profile-a"), "profiles/profile-1-link");
  tree.link("profile-1-link", "profiles/profile");

  QCOMPARE(resolve(tree, {tree.path("profiles/profile/share/applications")}),
           sorted({linkAt(tree.path("profiles/profile")),
                   linkAt(tree.path("profiles/profile-1-link"))}));
}

void WatchPointsTest::absoluteTargetRestartsAtRoot() {
  Tree tree;
  tree.mkdir("store/system-path/share/applications");
  tree.mkdir("store/system");
  tree.link(tree.path("store/system-path"), "store/system/sw");
  tree.mkdir("run");
  tree.link(tree.path("store/system"), "run/current-system");

  QCOMPARE(
      resolve(tree, {tree.path("run/current-system/sw/share/applications")}),
      std::vector<WatchPoint>({linkAt(tree.path("run/current-system"))}));
}

void WatchPointsTest::dotDotAfterLinkResolvesPhysically() {
  Tree tree;
  tree.mkdir("a/applications");
  tree.mkdir("b/c");
  tree.mkdir("b/applications");
  tree.link(tree.path("b/c"), "a/link");

  QCOMPARE(resolve(tree, {tree.path("a/link/../applications")}),
           sorted({linkAt(tree.path("a/link")),
                   contents(tree.path("b/applications"))}));
}

void WatchPointsTest::linkLoopStopsAtHopBudget() {
  Tree tree;
  tree.link(tree.path("b"), "a");
  tree.link(tree.path("a"), "b");

  QCOMPARE(resolve(tree, {tree.path("a/applications")}),
           sorted({linkAt(tree.path("a")), linkAt(tree.path("b"))}));
}

void WatchPointsTest::danglingChainAnchorsTheFirstMissingTarget() {
  Tree tree;
  tree.mkdir("profiles");
  tree.link(tree.path("profiles/gone"), "profiles/profile");

  QCOMPARE(resolve(tree, {tree.path("profiles/profile/share/applications")}),
           sorted({linkAt(tree.path("profiles/profile")),
                   missing(tree.path("profiles"), "gone")}));
}

void WatchPointsTest::onlyFirstMissingComponentIsAnchored() {
  Tree tree;
  tree.mkdir("state/nix");

  QCOMPARE(resolve(tree, {tree.path("state/nix/profile/share/applications")}),
           std::vector<WatchPoint>({missing(tree.path("state/nix"), "profile")}));
}

void WatchPointsTest::fileWhereDirectoryIsExpectedIsAnchoredAsMissing() {
  Tree tree;
  tree.mkdir("share");
  tree.file("share/applications");

  QCOMPARE(resolve(tree, {tree.path("share/applications")}),
           std::vector<WatchPoint>({missing(tree.path("share"), "applications")}));
}

void WatchPointsTest::redundantSeparatorsAndDotsAreIgnored() {
  Tree tree;
  tree.mkdir("home/applications");

  QCOMPARE(resolve(tree, {"/" + tree.path("home//./applications/")}),
           std::vector<WatchPoint>({contents(tree.path("home/applications"))}));
}

void WatchPointsTest::relativePathsAreRejected() {
  Tree tree;
  QCOMPARE(resolve(tree, {"relative/applications", ""}),
           std::vector<WatchPoint>());
}

void WatchPointsTest::unreadableDirectoryIsSkipped() {
  Tree tree;
  tree.mkdir("locked/applications");
  ::chmod(tree.path("locked").c_str(), 0);

  const auto points = resolve(tree, {tree.path("locked/applications")});
  ::chmod(tree.path("locked").c_str(), 0700);

  QCOMPARE(points, std::vector<WatchPoint>());
}

void WatchPointsTest::immutableRegionHasNoAnchors() {
  Tree tree;
  tree.mkdir("store/pkg/share/applications");
  tree.link(tree.path("store/pkg/share"), "store/pkg/alias");

  QCOMPARE(resolve(tree, {tree.path("store/pkg/share/applications"),
                          tree.path("store/pkg/alias/applications"),
                          tree.path("store/pkg/missing/applications"),
                          tree.store()}),
           std::vector<WatchPoint>());
}

void WatchPointsTest::immutableLinkBackIntoWritableDirectoryResumesAnchoring() {
  Tree tree;
  tree.mkdir("home/share/applications");
  tree.mkdir("store/pkg");
  tree.link(tree.path("home/share"), "store/pkg/share");

  QCOMPARE(resolve(tree, {tree.path("store/pkg/share/applications")}),
           std::vector<WatchPoint>(
               {contents(tree.path("home/share/applications"))}));
}

void WatchPointsTest::immutableRootMatchesWholeComponentsOnly() {
  Tree tree;
  tree.mkdir("store-extra/applications");

  QCOMPARE(resolve(tree, {tree.path("store-extra/applications")}),
           std::vector<WatchPoint>(
               {contents(tree.path("store-extra/applications"))}));
}

void WatchPointsTest::sharedAnchorsAreDeduplicated() {
  Tree tree;
  tree.mkdir("store/system/sw/share/applications");
  tree.mkdir("store/system/sw/share/icons");
  tree.mkdir("run");
  tree.link(tree.path("store/system"), "run/current-system");

  QCOMPARE(resolve(tree, {tree.path("run/current-system/sw/share/applications"),
                          tree.path("run/current-system/sw/share/icons")}),
           std::vector<WatchPoint>({linkAt(tree.path("run/current-system"))}));
}

void WatchPointsTest::subdirectoriesOfWritableContentsAreWatched() {
  Tree tree;
  tree.mkdir("home/applications/wine/Programs/Game");
  tree.file("home/applications/wine/notes.txt");

  QCOMPARE(resolve(tree, {tree.path("home/applications")}),
           sorted({contents(tree.path("home/applications")),
                   contents(tree.path("home/applications/wine")),
                   contents(tree.path("home/applications/wine/Programs")),
                   contents(tree.path("home/applications/wine/Programs/Game"))}));
}

void WatchPointsTest::subdirectoryLinkIsAnchoredAndFollowed() {
  Tree tree;
  tree.mkdir("store/kde4");
  tree.mkdir("home/extra");
  tree.mkdir("home/applications");
  tree.link(tree.path("store/kde4"), "home/applications/kde4");
  tree.link(tree.path("home/extra"), "home/applications/extra");

  QCOMPARE(resolve(tree, {tree.path("home/applications")}),
           sorted({contents(tree.path("home/applications")),
                   linkAt(tree.path("home/applications/kde4")),
                   linkAt(tree.path("home/applications/extra")),
                   contents(tree.path("home/extra"))}));
}

void WatchPointsTest::subdirectoryLinkLoopTerminates() {
  Tree tree;
  tree.mkdir("home/applications");
  tree.link(tree.path("home/applications"), "home/applications/loop");

  QCOMPARE(resolve(tree, {tree.path("home/applications")}),
           sorted({contents(tree.path("home/applications")),
                   linkAt(tree.path("home/applications/loop"))}));
}

QTEST_GUILESS_MAIN(WatchPointsTest)
#include "watchpoints_test.moc"
