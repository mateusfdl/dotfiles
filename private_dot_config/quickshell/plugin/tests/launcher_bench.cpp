#include "appsearch.hpp"
#include "desktopentry.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QTemporaryDir>
#include <QtTest/QTest>

#include <chrono>
#include <string>
#include <vector>

using namespace std::chrono_literals;

namespace {

constexpr int FIXTURE_APPS = 200;
constexpr int LOCALES = 40;
constexpr PathWatcher::Timing TIMING{.quiet = 100ms, .maxWait = 1000ms};

QByteArray desktopEntry(int index) {
  QByteArray text = "[Desktop Entry]\nType=Application\n";
  text += "Name=Application " + QByteArray::number(index) + "\n";
  text += "Exec=app-" + QByteArray::number(index) + " %U\n";
  text += "Icon=app-" + QByteArray::number(index) + "\n";
  text += "Comment=Does useful things, quickly; reliably\n";
  text += "Categories=GTK;Utility;Development;\n";
  for (int locale = 0; locale < LOCALES; ++locale) {
    text += "Name[l" + QByteArray::number(locale) + "]=Aplicativo " +
            QByteArray::number(index) + "\n";
    text += "Comment[l" + QByteArray::number(locale) +
            "]=Faz coisas uteis, rapidamente\n";
  }
  text += "[Desktop Action new]\nName=New\nExec=app --new\n";
  return text;
}

void writeFile(const QString &path, const QByteArray &contents) {
  QDir().mkpath(QFileInfo(path).absolutePath());
  QFile file(path);
  if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate))
    qFatal("cannot write %s", qPrintable(path));
  file.write(contents);
}

std::vector<WatchPoint> resolveOutsideStore(std::span<const std::string> paths) {
  return resolveWatchPoints(paths, "/nix/store");
}

} // namespace

class LauncherBench : public QObject {
  Q_OBJECT

private slots:
  void initTestCase();
  void coldScan();
  void warmRescan();
  void searchKeystroke();
  void parseLargeEntry();
  void realSystemRescan();

private:
  QTemporaryDir m_root;
  std::vector<std::string> m_dirs;
  QByteArray m_largeEntry;
};

void LauncherBench::initTestCase() {
  for (int index = 0; index < FIXTURE_APPS; ++index) {
    const QString subdir =
        index % 10 == 0 ? QStringLiteral("nested/") : QString();
    writeFile(m_root.filePath(QStringLiteral("system/") + subdir +
                              QStringLiteral("app-%1.desktop").arg(index)),
              desktopEntry(index));
  }
  m_dirs = {QFile::encodeName(m_root.filePath(QStringLiteral("system")))
                .toStdString()};
  m_largeEntry = desktopEntry(0);
  while (m_largeEntry.size() < 17000)
    m_largeEntry += "X-Padding=padding padding padding padding\n";
}

void LauncherBench::coldScan() {
  QBENCHMARK {
    const AppSearch search(m_dirs, resolveOutsideStore, TIMING, readDesktopFile, nullptr);
    QCOMPARE(search.applications().size(), FIXTURE_APPS);
  }
}

void LauncherBench::warmRescan() {
  AppSearch search(m_dirs, resolveOutsideStore, TIMING, readDesktopFile, nullptr);
  QBENCHMARK { search.refresh(); }
  QCOMPARE(search.applications().size(), FIXTURE_APPS);
}

void LauncherBench::searchKeystroke() {
  const AppSearch search(m_dirs, resolveOutsideStore, TIMING, readDesktopFile, nullptr);
  QVariantList results;
  QBENCHMARK { results = search.search(QStringLiteral("app 1")); }
  QCOMPARE_GT(results.size(), 0);
}

void LauncherBench::parseLargeEntry() {
  const std::string bytes = m_largeEntry.toStdString();
  DesktopEntry entry;
  QBENCHMARK { entry = DesktopEntry::parse(bytes); }
  QCOMPARE(entry.name, QStringLiteral("Application 0"));
}

void LauncherBench::realSystemRescan() {
  AppSearch search;
  QBENCHMARK { search.refresh(); }
  QCOMPARE_GT(search.applications().size(), 0);
}

QTEST_GUILESS_MAIN(LauncherBench)
#include "launcher_bench.moc"
