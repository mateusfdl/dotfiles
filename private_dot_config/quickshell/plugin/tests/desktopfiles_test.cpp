#include "desktopfiles.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QTemporaryDir>
#include <QtTest/QTest>

#include <sys/stat.h>
#include <unistd.h>

#include <string>
#include <tuple>
#include <vector>

namespace QTest {

template <> char *toString(const std::vector<DesktopFile> &files) {
  QString text;
  for (const auto &file : files)
    text += QStringLiteral("%1 -> %2 [%3:%4 %5B]\n")
                .arg(file.id, QString::fromStdString(file.path))
                .arg(file.key.device)
                .arg(file.key.inode)
                .arg(file.key.size);
  return qstrdup(text.toUtf8().constData());
}

} // namespace QTest

namespace {

std::string pathOf(const QTemporaryDir &root, const QString &relative) {
  return QFile::encodeName(root.filePath(relative)).toStdString();
}

void writeFile(const QTemporaryDir &root, const QString &relative,
               const QByteArray &contents = "[Desktop Entry]\n") {
  const QString path = root.filePath(relative);
  QDir().mkpath(QFileInfo(path).absolutePath());
  QFile file(path);
  if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate))
    qFatal("cannot write %s", qPrintable(path));
  file.write(contents);
}

void symlinkAt(const QTemporaryDir &root, const QString &target,
               const QString &relative) {
  const auto link = pathOf(root, relative);
  QDir().mkpath(QFileInfo(root.filePath(relative)).absolutePath());
  if (::symlink(QFile::encodeName(target).constData(), link.c_str()) != 0)
    qFatal("cannot symlink %s", link.c_str());
}

DesktopFile file(const QTemporaryDir &root, const char *id,
                 const char *relative) {
  const auto path = pathOf(root, QLatin1String(relative));
  struct stat status{};
  if (::stat(path.c_str(), &status) != 0)
    qFatal("cannot stat %s", path.c_str());
  return {QString::fromLatin1(id), path, FileKey::of(status)};
}

} // namespace

class DesktopFilesTest : public QObject {
  Q_OBJECT

private slots:
  void listsDesktopFilesSortedByName();
  void prefixesSubdirectoryIdsPerSpec();
  void firstDirectoryMasksLaterDirectories();
  void followsSymlinksToFiles();
  void followsSymlinksToDirectories();
  void directorySymlinkLoopTerminates();
  void skipsMissingDirectoriesAndOtherFiles();
  void ignoresRelativeDirectories();
  void readsWholeFile();
  void throwsWhenFileCannotBeRead();
};

void DesktopFilesTest::listsDesktopFilesSortedByName() {
  QTemporaryDir root;
  writeFile(root, QStringLiteral("apps/zed.desktop"));
  writeFile(root, QStringLiteral("apps/alacritty.desktop"));
  writeFile(root, QStringLiteral("apps/kitty.desktop"));

  const std::vector<std::string> dirs = {pathOf(root, QStringLiteral("apps"))};

  QCOMPARE(listDesktopFiles(dirs),
           std::vector<DesktopFile>({
               file(root, "alacritty.desktop", "apps/alacritty.desktop"),
               file(root, "kitty.desktop", "apps/kitty.desktop"),
               file(root, "zed.desktop", "apps/zed.desktop"),
           }));
}

void DesktopFilesTest::prefixesSubdirectoryIdsPerSpec() {
  QTemporaryDir root;
  writeFile(root, QStringLiteral("apps/foo.desktop"));
  writeFile(root, QStringLiteral("apps/kde4/foo.desktop"));
  writeFile(root, QStringLiteral("apps/wine/Programs/Game/play.desktop"));

  const std::vector<std::string> dirs = {pathOf(root, QStringLiteral("apps"))};

  QCOMPARE(listDesktopFiles(dirs),
           std::vector<DesktopFile>({
               file(root, "foo.desktop", "apps/foo.desktop"),
               file(root, "kde4-foo.desktop", "apps/kde4/foo.desktop"),
               file(root, "wine-Programs-Game-play.desktop",
                    "apps/wine/Programs/Game/play.desktop"),
           }));
}

void DesktopFilesTest::firstDirectoryMasksLaterDirectories() {
  QTemporaryDir root;
  writeFile(root, QStringLiteral("user/tool.desktop"));
  writeFile(root, QStringLiteral("system/tool.desktop"));
  writeFile(root, QStringLiteral("system/other.desktop"));

  const std::vector<std::string> dirs = {
      pathOf(root, QStringLiteral("user")),
      pathOf(root, QStringLiteral("system")),
  };

  QCOMPARE(listDesktopFiles(dirs),
           std::vector<DesktopFile>({
               file(root, "tool.desktop", "user/tool.desktop"),
               file(root, "other.desktop", "system/other.desktop"),
           }));
}

void DesktopFilesTest::followsSymlinksToFiles() {
  QTemporaryDir root;
  writeFile(root, QStringLiteral("store/btop.desktop"));
  symlinkAt(root, root.filePath(QStringLiteral("store/btop.desktop")),
            QStringLiteral("apps/btop.desktop"));
  symlinkAt(root, root.filePath(QStringLiteral("store/missing.desktop")),
            QStringLiteral("apps/dangling.desktop"));

  const std::vector<std::string> dirs = {pathOf(root, QStringLiteral("apps"))};

  QCOMPARE(listDesktopFiles(dirs),
           std::vector<DesktopFile>(
               {file(root, "btop.desktop", "apps/btop.desktop")}));
}

void DesktopFilesTest::followsSymlinksToDirectories() {
  QTemporaryDir root;
  writeFile(root, QStringLiteral("store/kde4/foo.desktop"));
  symlinkAt(root, root.filePath(QStringLiteral("store/kde4")),
            QStringLiteral("apps/kde4"));

  const std::vector<std::string> dirs = {pathOf(root, QStringLiteral("apps"))};

  QCOMPARE(listDesktopFiles(dirs),
           std::vector<DesktopFile>(
               {file(root, "kde4-foo.desktop", "apps/kde4/foo.desktop")}));
}

void DesktopFilesTest::directorySymlinkLoopTerminates() {
  QTemporaryDir root;
  writeFile(root, QStringLiteral("apps/real.desktop"));
  symlinkAt(root, root.filePath(QStringLiteral("apps")),
            QStringLiteral("apps/loop"));

  const std::vector<std::string> dirs = {pathOf(root, QStringLiteral("apps"))};

  QCOMPARE(listDesktopFiles(dirs),
           std::vector<DesktopFile>(
               {file(root, "real.desktop", "apps/real.desktop")}));
}

void DesktopFilesTest::skipsMissingDirectoriesAndOtherFiles() {
  QTemporaryDir root;
  writeFile(root, QStringLiteral("apps/notes.txt"));
  writeFile(root, QStringLiteral("apps/.hidden.desktop"));
  writeFile(root, QStringLiteral("apps/real.desktop"));
  QDir().mkpath(root.filePath(QStringLiteral("apps/folder.desktop")));

  const std::vector<std::string> dirs = {
      pathOf(root, QStringLiteral("missing")),
      pathOf(root, QStringLiteral("apps")),
  };

  QCOMPARE(listDesktopFiles(dirs),
           std::vector<DesktopFile>(
               {file(root, "real.desktop", "apps/real.desktop")}));
}

void DesktopFilesTest::ignoresRelativeDirectories() {
  QTemporaryDir root;
  writeFile(root, QStringLiteral("apps/relative.desktop"));
  const QString previous = QDir::currentPath();
  QDir::setCurrent(root.path());

  const std::vector<std::string> dirs = {"apps", "./apps"};
  const auto files = listDesktopFiles(dirs);
  QDir::setCurrent(previous);

  QCOMPARE(files, std::vector<DesktopFile>());
}

void DesktopFilesTest::readsWholeFile() {
  QTemporaryDir root;
  QByteArray contents(70000, 'x');
  contents.prepend("[Desktop Entry]\n");
  writeFile(root, QStringLiteral("apps/big.desktop"), contents);

  QCOMPARE(readDesktopFile(pathOf(root, QStringLiteral("apps/big.desktop"))),
           contents.toStdString());
}

void DesktopFilesTest::throwsWhenFileCannotBeRead() {
  QTemporaryDir root;
  QVERIFY_THROWS_EXCEPTION(
      DesktopFileReadError,
      std::ignore = readDesktopFile(
          pathOf(root, QStringLiteral("apps/missing.desktop"))));
}

QTEST_GUILESS_MAIN(DesktopFilesTest)
#include "desktopfiles_test.moc"
