#include "appsearch.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QSignalSpy>
#include <QTemporaryDir>
#include <QtTest/QTest>

#include <unistd.h>

#include <chrono>
#include <string>
#include <vector>

using namespace std::chrono_literals;

namespace {

constexpr PathWatcher::Timing FAST{.quiet = 10ms, .maxWait = 100ms};

void writeFile(const QString &path, const QByteArray &contents) {
  QDir().mkpath(QFileInfo(path).absolutePath());
  QFile file(path);
  if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate))
    qFatal("cannot write %s", qPrintable(path));
  file.write(contents);
}

QVariantMap app(const QString &id, const QString &name, const QString &exec,
                const QString &category, const QString &icon = {},
                const QString &comment = {}) {
  return {
      {QStringLiteral("id"), id},
      {QStringLiteral("name"), name},
      {QStringLiteral("icon"), icon},
      {QStringLiteral("comment"), comment},
      {QStringLiteral("exec"), exec},
      {QStringLiteral("path"), QString()},
      {QStringLiteral("category"), category},
      {QStringLiteral("terminal"), false},
  };
}

QByteArray json(const QVariantList &apps) {
  return QJsonDocument::fromVariant(apps).toJson(QJsonDocument::Indented);
}

std::string physical(const QTemporaryDir &root, const QString &relative) {
  return QFile::encodeName(QFileInfo(root.path()).canonicalFilePath() + u'/' +
                           relative)
      .toStdString();
}

PathWatcher::Resolver resolver(const QTemporaryDir &root) {
  return [store = physical(root, QStringLiteral("store"))](
             std::span<const std::string> paths) {
    return resolveWatchPoints(paths, store);
  };
}

void swapLink(const QTemporaryDir &root, const QString &target,
              const QString &link) {
  const auto temporary = physical(root, link + QStringLiteral(".tmp"));
  if (::symlink(physical(root, target).c_str(), temporary.c_str()) != 0 ||
      ::rename(temporary.c_str(), physical(root, link).c_str()) != 0)
    qFatal("cannot swap %s", qPrintable(link));
}

std::vector<std::string> dirs(const QTemporaryDir &root,
                              std::initializer_list<const char *> names) {
  std::vector<std::string> result;
  for (const char *name : names)
    result.push_back(physical(root, QLatin1String(name)));
  return result;
}

} // namespace

class AppSearchTest : public QObject {
  Q_OBJECT

private slots:
  void listsApplicationsFromInjectedDirsSortedByName();
  void firstDirWinsForTheSameId();
  void keepsCommasAndEveryCategory();
  void hiddenOrInvalidEntryMasksLowerPriorityCopy();
  void prefixesSubdirectoryIds();
  void refreshesAfterLinkedDataDirIsSwapped();
  void picksUpApplicationsDirCreatedLater();
  void picksUpEntryInNestedSubdirectoryCreatedLater();
  void unchangedRescanEmitsNothing();
  void commentOnlyChangeEmits();
  void renameThatUnshadowsLowerCopyEmits();
  void unchangedFilesAreNotReadAgain();
  void sameFileUnderTwoIdsKeepsEachId();
  void searchRanksFuzzyMatchesByName();
};

void AppSearchTest::listsApplicationsFromInjectedDirsSortedByName() {
  QTemporaryDir root;
  writeFile(root.filePath(QStringLiteral("user/editor.desktop")),
            "[Desktop Entry]\nType=Application\nName=Editor\nExec=editor "
            "%F\nIcon=editor\nComment=Edit text\nCategories=Development;\n");
  writeFile(root.filePath(QStringLiteral("system/browser.desktop")),
            "[Desktop Entry]\nType=Application\nName=Browser\nExec=browser "
            "%U\nCategories=Network;\n");
  writeFile(root.filePath(QStringLiteral("system/hidden.desktop")),
            "[Desktop Entry]\nType=Application\nName=Hidden\nExec=hidden\n"
            "NoDisplay=true\n");

  const AppSearch search(dirs(root, {"user", "system"}), resolver(root), FAST, readDesktopFile, nullptr);

  const QVariantList expected = {
      app(QStringLiteral("browser.desktop"), QStringLiteral("Browser"),
          QStringLiteral("browser %U"), QStringLiteral("Social")),
      app(QStringLiteral("editor.desktop"), QStringLiteral("Editor"),
          QStringLiteral("editor %F"), QStringLiteral("Developer Tools"),
          QStringLiteral("editor"), QStringLiteral("Edit text")),
  };
  QCOMPARE(json(search.applications()), json(expected));
}

void AppSearchTest::firstDirWinsForTheSameId() {
  QTemporaryDir root;
  writeFile(root.filePath(QStringLiteral("user/tool.desktop")),
            "[Desktop Entry]\nType=Application\nName=User Tool\nExec=user\n");
  writeFile(
      root.filePath(QStringLiteral("system/tool.desktop")),
      "[Desktop Entry]\nType=Application\nName=System Tool\nExec=system\n");

  const AppSearch search(dirs(root, {"user", "system"}), resolver(root), FAST, readDesktopFile, nullptr);

  const QVariantList expected = {
      app(QStringLiteral("tool.desktop"), QStringLiteral("User Tool"),
          QStringLiteral("user"), QStringLiteral("Other")),
  };
  QCOMPARE(json(search.applications()), json(expected));
}

void AppSearchTest::keepsCommasAndEveryCategory() {
  QTemporaryDir root;
  writeFile(root.filePath(QStringLiteral("system/btop.desktop")),
            "[Desktop Entry]\nType=Application\nName=btop++\nExec=btop\n"
            "Comment=Resource monitor for processor, memory, disks\n"
            "Categories=GTK;Utility;\n");

  const AppSearch search(dirs(root, {"system"}), resolver(root), FAST, readDesktopFile, nullptr);

  const QVariantList expected = {
      app(QStringLiteral("btop.desktop"), QStringLiteral("btop++"),
          QStringLiteral("btop"), QStringLiteral("Utilities"), QString(),
          QStringLiteral("Resource monitor for processor, memory, disks")),
  };
  QCOMPARE(json(search.applications()), json(expected));
}

void AppSearchTest::hiddenOrInvalidEntryMasksLowerPriorityCopy() {
  QTemporaryDir root;
  writeFile(root.filePath(QStringLiteral("user/tool.desktop")),
            "[Desktop Entry]\nType=Application\nName=Tool\nExec=tool\n"
            "Hidden=true\n");
  writeFile(root.filePath(QStringLiteral("user/broken.desktop")),
            "[Desktop Entry]\nType=Application\nName=Broken\n");
  writeFile(root.filePath(QStringLiteral("system/tool.desktop")),
            "[Desktop Entry]\nType=Application\nName=Tool\nExec=tool\n");
  writeFile(root.filePath(QStringLiteral("system/broken.desktop")),
            "[Desktop Entry]\nType=Application\nName=Broken\nExec=broken\n");

  const AppSearch search(dirs(root, {"user", "system"}), resolver(root), FAST, readDesktopFile, nullptr);

  QCOMPARE(json(search.applications()), json(QVariantList()));
}

void AppSearchTest::prefixesSubdirectoryIds() {
  QTemporaryDir root;
  writeFile(root.filePath(QStringLiteral("system/kde4/konsole.desktop")),
            "[Desktop Entry]\nType=Application\nName=Konsole\nExec=konsole\n");

  const AppSearch search(dirs(root, {"system"}), resolver(root), FAST, readDesktopFile, nullptr);

  const QVariantList expected = {
      app(QStringLiteral("kde4-konsole.desktop"), QStringLiteral("Konsole"),
          QStringLiteral("konsole"), QStringLiteral("Other")),
  };
  QCOMPARE(json(search.applications()), json(expected));
}

void AppSearchTest::refreshesAfterLinkedDataDirIsSwapped() {
  QTemporaryDir root;
  const QByteArray alpha =
      "[Desktop Entry]\nType=Application\nName=Alpha\nExec=alpha\n";
  const QByteArray beta =
      "[Desktop Entry]\nType=Application\nName=Beta\nExec=beta\n";
  writeFile(root.filePath(QStringLiteral("store/gen-1/applications/alpha.desktop")), alpha);
  writeFile(root.filePath(QStringLiteral("store/gen-2/applications/alpha.desktop")), alpha);
  writeFile(root.filePath(QStringLiteral("store/gen-2/applications/beta.desktop")), beta);
  QDir().mkpath(root.filePath(QStringLiteral("run")));
  swapLink(root, QStringLiteral("store/gen-1"), QStringLiteral("run/current-system"));
  const AppSearch search(dirs(root, {"run/current-system/applications"}),
                         resolver(root), FAST, readDesktopFile, nullptr);
  QSignalSpy changed(&search, &AppSearch::applicationsChanged);

  swapLink(root, QStringLiteral("store/gen-2"), QStringLiteral("run/current-system"));

  QTRY_COMPARE(changed.count(), 1);
  const QVariantList expected = {
      app(QStringLiteral("alpha.desktop"), QStringLiteral("Alpha"),
          QStringLiteral("alpha"), QStringLiteral("Other")),
      app(QStringLiteral("beta.desktop"), QStringLiteral("Beta"),
          QStringLiteral("beta"), QStringLiteral("Other")),
  };
  QCOMPARE(json(search.applications()), json(expected));
}

void AppSearchTest::picksUpApplicationsDirCreatedLater() {
  QTemporaryDir root;
  QDir().mkpath(root.filePath(QStringLiteral("state")));
  const AppSearch search(dirs(root, {"state/profile/applications"}),
                         resolver(root), FAST, readDesktopFile, nullptr);
  QSignalSpy changed(&search, &AppSearch::applicationsChanged);
  QCOMPARE(json(search.applications()), json(QVariantList()));

  writeFile(root.filePath(QStringLiteral("state/profile/applications/xterm.desktop")),
            "[Desktop Entry]\nType=Application\nName=XTerm\nExec=xterm\n");

  const QVariantList expected = {
      app(QStringLiteral("xterm.desktop"), QStringLiteral("XTerm"),
          QStringLiteral("xterm"), QStringLiteral("Other")),
  };
  QTRY_COMPARE(json(search.applications()), json(expected));
}

void AppSearchTest::picksUpEntryInNestedSubdirectoryCreatedLater() {
  QTemporaryDir root;
  QDir().mkpath(root.filePath(QStringLiteral("home/applications")));
  const AppSearch search(dirs(root, {"home/applications"}), resolver(root),
                         FAST, readDesktopFile, nullptr);
  QSignalSpy rewatched(&search.m_watcher, &PathWatcher::changed);

  QDir().mkpath(
      root.filePath(QStringLiteral("home/applications/wine/Programs/Game")));
  QTRY_COMPARE(rewatched.count(), 1);
  writeFile(root.filePath(QStringLiteral(
                "home/applications/wine/Programs/Game/play.desktop")),
            "[Desktop Entry]\nType=Application\nName=Game\nExec=wine "
            "game.exe\n");

  const QVariantList expected = {
      app(QStringLiteral("wine-Programs-Game-play.desktop"),
          QStringLiteral("Game"), QStringLiteral("wine game.exe"),
          QStringLiteral("Other")),
  };
  QTRY_COMPARE(json(search.applications()), json(expected));
}

void AppSearchTest::unchangedRescanEmitsNothing() {
  QTemporaryDir root;
  writeFile(root.filePath(QStringLiteral("system/tool.desktop")),
            "[Desktop Entry]\nType=Application\nName=Tool\nExec=tool\n");
  AppSearch search(dirs(root, {"system"}), resolver(root), FAST, readDesktopFile, nullptr);
  QSignalSpy changed(&search, &AppSearch::applicationsChanged);

  search.refresh();
  search.refresh();

  QCOMPARE(changed.count(), 0);
  const QVariantList expected = {
      app(QStringLiteral("tool.desktop"), QStringLiteral("Tool"),
          QStringLiteral("tool"), QStringLiteral("Other")),
  };
  QCOMPARE(json(search.applications()), json(expected));
}

void AppSearchTest::commentOnlyChangeEmits() {
  QTemporaryDir root;
  const QString path = root.filePath(QStringLiteral("system/tool.desktop"));
  writeFile(path, "[Desktop Entry]\nType=Application\nName=Tool\nExec=tool\n"
                  "Comment=Old\n");
  AppSearch search(dirs(root, {"system"}), resolver(root), FAST, readDesktopFile, nullptr);
  QSignalSpy changed(&search, &AppSearch::applicationsChanged);

  writeFile(path, "[Desktop Entry]\nType=Application\nName=Tool\nExec=tool\n"
                  "Comment=New\n");
  search.refresh();

  QCOMPARE(changed.count(), 1);
  QTest::qWait(250);
  QCOMPARE(changed.count(), 1);
  const QVariantList expected = {
      app(QStringLiteral("tool.desktop"), QStringLiteral("Tool"),
          QStringLiteral("tool"), QStringLiteral("Other"), QString(),
          QStringLiteral("New")),
  };
  QCOMPARE(json(search.applications()), json(expected));
}

void AppSearchTest::renameThatUnshadowsLowerCopyEmits() {
  QTemporaryDir root;
  writeFile(root.filePath(QStringLiteral("user/foo.desktop")),
            "[Desktop Entry]\nType=Application\nName=User Foo\nExec=user\n");
  writeFile(root.filePath(QStringLiteral("system/foo.desktop")),
            "[Desktop Entry]\nType=Application\nName=System Foo\nExec=system\n");
  AppSearch search(dirs(root, {"user", "system"}), resolver(root), FAST,
                   readDesktopFile, nullptr);
  QSignalSpy changed(&search, &AppSearch::applicationsChanged);

  QFile::rename(root.filePath(QStringLiteral("user/foo.desktop")),
                root.filePath(QStringLiteral("user/bar.desktop")));
  search.refresh();

  QCOMPARE(changed.count(), 1);
  const QVariantList expected = {
      app(QStringLiteral("foo.desktop"), QStringLiteral("System Foo"),
          QStringLiteral("system"), QStringLiteral("Other")),
      app(QStringLiteral("bar.desktop"), QStringLiteral("User Foo"),
          QStringLiteral("user"), QStringLiteral("Other")),
  };
  QCOMPARE(json(search.applications()), json(expected));
}

void AppSearchTest::unchangedFilesAreNotReadAgain() {
  QTemporaryDir root;
  writeFile(root.filePath(QStringLiteral("system/alpha.desktop")),
            "[Desktop Entry]\nType=Application\nName=Alpha\nExec=alpha\n");
  writeFile(root.filePath(QStringLiteral("system/beta.desktop")),
            "[Desktop Entry]\nType=Application\nName=Beta\nExec=beta\n");
  std::vector<std::string> reads;
  AppSearch search(
      dirs(root, {"system"}), resolver(root), FAST,
      [&](const std::string &path) {
        reads.push_back(path);
        return readDesktopFile(path);
      },
      nullptr);
  reads.clear();

  search.refresh();
  QCOMPARE(reads, std::vector<std::string>());

  writeFile(root.filePath(QStringLiteral("system/beta.desktop")),
            "[Desktop Entry]\nType=Application\nName=Beta 2\nExec=beta\n");
  search.refresh();
  QCOMPARE(reads, std::vector<std::string>(
                      {physical(root, QStringLiteral("system/beta.desktop"))}));
}

void AppSearchTest::sameFileUnderTwoIdsKeepsEachId() {
  QTemporaryDir root;
  writeFile(root.filePath(QStringLiteral("system/firefox.desktop")),
            "[Desktop Entry]\nType=Application\nName=Firefox\nExec=firefox\n");
  QDir().mkpath(root.filePath(QStringLiteral("user")));
  if (::symlink(physical(root, QStringLiteral("system/firefox.desktop")).c_str(),
                physical(root, QStringLiteral("user/browser.desktop")).c_str()) != 0)
    qFatal("cannot link alias");
  AppSearch search(dirs(root, {"user", "system"}), resolver(root), FAST,
                   readDesktopFile, nullptr);
  search.refresh();

  const QVariantList expected = {
      app(QStringLiteral("browser.desktop"), QStringLiteral("Firefox"),
          QStringLiteral("firefox"), QStringLiteral("Other")),
      app(QStringLiteral("firefox.desktop"), QStringLiteral("Firefox"),
          QStringLiteral("firefox"), QStringLiteral("Other")),
  };
  QCOMPARE(json(search.applications()), json(expected));
}

void AppSearchTest::searchRanksFuzzyMatchesByName() {
  QTemporaryDir root;
  writeFile(root.filePath(QStringLiteral("system/kitty.desktop")),
            "[Desktop Entry]\nType=Application\nName=Kitty Terminal\n"
            "Exec=kitty\n");
  writeFile(root.filePath(QStringLiteral("system/terminator.desktop")),
            "[Desktop Entry]\nType=Application\nName=Terminator\n"
            "Exec=terminator\n");
  writeFile(root.filePath(QStringLiteral("system/steam.desktop")),
            "[Desktop Entry]\nType=Application\nName=Steam\nExec=steam\n");
  const AppSearch search(dirs(root, {"system"}), resolver(root), FAST,
                         readDesktopFile, nullptr);

  const QVariantList expected = {
      app(QStringLiteral("terminator.desktop"), QStringLiteral("Terminator"),
          QStringLiteral("terminator"), QStringLiteral("Other")),
      app(QStringLiteral("kitty.desktop"), QStringLiteral("Kitty Terminal"),
          QStringLiteral("kitty"), QStringLiteral("Other")),
  };
  QCOMPARE(json(search.search(QStringLiteral("term"))), json(expected));
  QCOMPARE(json(search.search(QStringLiteral("zzz"))), json(QVariantList()));
}

QTEST_GUILESS_MAIN(AppSearchTest)
#include "appsearch_test.moc"
