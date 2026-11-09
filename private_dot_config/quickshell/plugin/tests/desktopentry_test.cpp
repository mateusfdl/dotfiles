#include "desktopentry.hpp"

#include <QtTest/QTest>

#include <string_view>

using namespace std::string_view_literals;

namespace QTest {

template <> char *toString(const DesktopEntry &entry) {
  const auto text =
      QStringLiteral("DesktopEntry{type=%1 name=%2 exec=%3 icon=%4 comment=%5 "
                     "path=%6 categories=[%7] onlyShowIn=[%8] notShowIn=[%9] "
                     "hidden=%10 noDisplay=%11 terminal=%12}")
          .arg(entry.type, entry.name, entry.exec, entry.icon, entry.comment,
               entry.path, entry.categories.join(u'|'),
               entry.onlyShowIn.join(u'|'), entry.notShowIn.join(u'|'))
          .arg(entry.hidden)
          .arg(entry.noDisplay)
          .arg(entry.terminal);
  return qstrdup(text.toUtf8().constData());
}

} // namespace QTest

namespace {

DesktopEntry application(const QString &name, const QString &exec) {
  DesktopEntry entry;
  entry.type = QStringLiteral("Application");
  entry.name = name;
  entry.exec = exec;
  return entry;
}

} // namespace

class DesktopEntryTest : public QObject {
  Q_OBJECT

private slots:
  void parsesEveryKnownKey();
  void keepsCommasInStrings();
  void splitsListsOnUnescapedSemicolons();
  void decodesStringEscapes();
  void keepsSemicolonsAndUnknownEscapesInStrings();
  void ignoresDesktopActionGroups();
  void ignoresKeysOutsideDesktopEntryGroup();
  void keepsLastDuplicateKey();
  void ignoresLocalizedKeys();
  void trimsSpacesAroundEquals();
  void acceptsCrlfBomAndMissingFinalNewline();
  void skipsCommentsAndBlankLines();
  void keepsEmbeddedNul();
  void replacesInvalidUtf8();
  void parsesBooleans_data();
  void parsesBooleans();
  void keepsExecQuotesVerbatim();
  void keepsEmptyValues();
  void returnsEmptyEntryWithoutGroup();
  void filtersVisibility_data();
  void filtersVisibility();
};

void DesktopEntryTest::parsesEveryKnownKey() {
  const auto entry = DesktopEntry::parse("[Desktop Entry]\n"
                                         "Type=Application\n"
                                         "Name=Paseo\n"
                                         "Exec=paseo-desktop --class=Paseo %U\n"
                                         "Icon=Paseo\n"
                                         "Comment=Run coding agents\n"
                                         "Path=/srv/work\n"
                                         "Terminal=false\n"
                                         "Hidden=false\n"
                                         "NoDisplay=false\n"
                                         "Categories=Development;IDE;\n"
                                         "OnlyShowIn=Hyprland;GNOME;\n"
                                         "NotShowIn=KDE;\n"sv);

  DesktopEntry expected = application(
      QStringLiteral("Paseo"), QStringLiteral("paseo-desktop --class=Paseo %U"));
  expected.icon = QStringLiteral("Paseo");
  expected.comment = QStringLiteral("Run coding agents");
  expected.path = QStringLiteral("/srv/work");
  expected.categories = {QStringLiteral("Development"), QStringLiteral("IDE")};
  expected.onlyShowIn = {QStringLiteral("Hyprland"), QStringLiteral("GNOME")};
  expected.notShowIn = {QStringLiteral("KDE")};
  QCOMPARE(entry, expected);
}

void DesktopEntryTest::keepsCommasInStrings() {
  const auto entry = DesktopEntry::parse(
      "[Desktop Entry]\nComment=Fast, feature-rich, GPU based terminal\n"sv);
  QCOMPARE(entry.comment,
           QStringLiteral("Fast, feature-rich, GPU based terminal"));
}

void DesktopEntryTest::splitsListsOnUnescapedSemicolons() {
  const auto entry = DesktopEntry::parse("[Desktop Entry]\n"
                                         "Categories=GTK;Utility;\n"
                                         "OnlyShowIn=A\\;B;C\\\\;;D\n"sv);
  QCOMPARE(entry.categories,
           QStringList({QStringLiteral("GTK"), QStringLiteral("Utility")}));
  QCOMPARE(entry.onlyShowIn,
           QStringList({QStringLiteral("A;B"), QStringLiteral("C\\"),
                        QStringLiteral("D")}));
}

void DesktopEntryTest::decodesStringEscapes() {
  const auto entry = DesktopEntry::parse(
      "[Desktop Entry]\nComment=\\sa\\nb\\tc\\rd\\\\e\n"sv);
  QCOMPARE(entry.comment, QStringLiteral(" a\nb\tc\rd\\e"));
}

void DesktopEntryTest::keepsSemicolonsAndUnknownEscapesInStrings() {
  const auto entry =
      DesktopEntry::parse("[Desktop Entry]\nName=a\\;b;c\\x\\\n"sv);
  QCOMPARE(entry.name, QStringLiteral("a\\;b;c\\x\\"));
}

void DesktopEntryTest::ignoresDesktopActionGroups() {
  const auto entry = DesktopEntry::parse("[Desktop Entry]\n"
                                         "Type=Application\n"
                                         "Name=Kitty\n"
                                         "Exec=kitty\n"
                                         "[Desktop Action new-window]\n"
                                         "Name=New Window\n"
                                         "Exec=kitty --new-window\n"sv);
  QCOMPARE(entry,
           application(QStringLiteral("Kitty"), QStringLiteral("kitty")));
}

void DesktopEntryTest::ignoresKeysOutsideDesktopEntryGroup() {
  const auto entry = DesktopEntry::parse("Name=Before Any Group\n"
                                         "[Other Group]\n"
                                         "Name=Other\n"
                                         "[Desktop Entry]\n"
                                         "Type=Application\n"
                                         "Name=Real\n"
                                         "Exec=real\n"sv);
  QCOMPARE(entry, application(QStringLiteral("Real"), QStringLiteral("real")));
}

void DesktopEntryTest::keepsLastDuplicateKey() {
  const auto entry =
      DesktopEntry::parse("[Desktop Entry]\nName=First\nName=Second\n"sv);
  QCOMPARE(entry.name, QStringLiteral("Second"));
}

void DesktopEntryTest::ignoresLocalizedKeys() {
  const auto entry = DesktopEntry::parse("[Desktop Entry]\n"
                                         "Name[pt_BR]=Navegador\n"
                                         "Name=Browser\n"
                                         "Comment[de]=Nur lokal\n"sv);
  QCOMPARE(entry.name, QStringLiteral("Browser"));
  QCOMPARE(entry.comment, QString());
}

void DesktopEntryTest::trimsSpacesAroundEquals() {
  const auto entry =
      DesktopEntry::parse("[Desktop Entry]\nName \t=  Spaced Out \t\n"sv);
  QCOMPARE(entry.name, QStringLiteral("Spaced Out"));
}

void DesktopEntryTest::acceptsCrlfBomAndMissingFinalNewline() {
  const auto entry = DesktopEntry::parse("\xEF\xBB\xBF[Desktop Entry]\r\n"
                                         "Type=Application\r\n"
                                         "Name=Wine App\r\n"
                                         "Exec=wine app.exe"sv);
  QCOMPARE(entry, application(QStringLiteral("Wine App"),
                              QStringLiteral("wine app.exe")));
}

void DesktopEntryTest::skipsCommentsAndBlankLines() {
  const auto entry = DesktopEntry::parse("# leading comment\n"
                                         "\n"
                                         "[Desktop Entry]\n"
                                         "  # indented comment\n"
                                         "\t\n"
                                         "Type=Application\n"
                                         "Name=Btop\n"
                                         "Exec=btop\n"
                                         "no equals sign here\n"sv);
  QCOMPARE(entry, application(QStringLiteral("Btop"), QStringLiteral("btop")));
}

void DesktopEntryTest::keepsEmbeddedNul() {
  const auto entry = DesktopEntry::parse("[Desktop Entry]\nName=a\0b\n"sv);
  QCOMPARE(entry.name, QString::fromUtf8("a\0b", 3));
}

void DesktopEntryTest::replacesInvalidUtf8() {
  const auto entry = DesktopEntry::parse("[Desktop Entry]\nName=a\xFF"
                                         "b\n"sv);
  QCOMPARE(entry.name, QStringLiteral("a�b"));
}

void DesktopEntryTest::parsesBooleans_data() {
  QTest::addColumn<QByteArray>("value");
  QTest::addColumn<bool>("expected");
  QTest::newRow("true") << QByteArray("true") << true;
  QTest::newRow("one") << QByteArray("1") << true;
  QTest::newRow("false") << QByteArray("false") << false;
  QTest::newRow("zero") << QByteArray("0") << false;
  QTest::newRow("yes") << QByteArray("yes") << false;
  QTest::newRow("empty") << QByteArray("") << false;
}

void DesktopEntryTest::parsesBooleans() {
  QFETCH(QByteArray, value);
  QFETCH(bool, expected);
  const QByteArray text = "[Desktop Entry]\nTerminal=" + value +
                          "\nHidden=" + value + "\nNoDisplay=" + value + "\n";
  const auto entry =
      DesktopEntry::parse(std::string_view(text.constData(), text.size()));
  QCOMPARE(entry.terminal, expected);
  QCOMPARE(entry.hidden, expected);
  QCOMPARE(entry.noDisplay, expected);
}

void DesktopEntryTest::keepsExecQuotesVerbatim() {
  const auto entry = DesktopEntry::parse(
      "[Desktop Entry]\nExec=\"/opt/my app/run\" --flag \"%f\" %%\n"sv);
  QCOMPARE(entry.exec, QStringLiteral("\"/opt/my app/run\" --flag \"%f\" %%"));
}

void DesktopEntryTest::keepsEmptyValues() {
  const auto entry =
      DesktopEntry::parse("[Desktop Entry]\nIcon=\nCategories=\n"sv);
  QCOMPARE(entry.icon, QString());
  QCOMPARE(entry.categories, QStringList());
}

void DesktopEntryTest::returnsEmptyEntryWithoutGroup() {
  QCOMPARE(DesktopEntry::parse("Type=Application\nName=X\nExec=x\n"sv),
           DesktopEntry());
  QCOMPARE(DesktopEntry::parse(""sv), DesktopEntry());
}

void DesktopEntryTest::filtersVisibility_data() {
  QTest::addColumn<DesktopEntry>("entry");
  QTest::addColumn<bool>("shown");

  const auto base = application(QStringLiteral("App"), QStringLiteral("app"));
  QTest::newRow("application") << base << true;

  auto link = base;
  link.type = QStringLiteral("Link");
  QTest::newRow("not an application") << link << false;

  auto hidden = base;
  hidden.hidden = true;
  QTest::newRow("hidden") << hidden << false;

  auto noDisplay = base;
  noDisplay.noDisplay = true;
  QTest::newRow("no display") << noDisplay << false;

  auto unnamed = base;
  unnamed.name.clear();
  QTest::newRow("empty name") << unnamed << false;

  auto noExec = base;
  noExec.exec.clear();
  QTest::newRow("empty exec") << noExec << false;

  auto onlyGnome = base;
  onlyGnome.onlyShowIn = {QStringLiteral("GNOME")};
  QTest::newRow("only shown elsewhere") << onlyGnome << false;

  auto onlyHyprland = base;
  onlyHyprland.onlyShowIn = {QStringLiteral("GNOME"),
                             QStringLiteral("hyprland")};
  QTest::newRow("only shown here, any case") << onlyHyprland << true;

  auto notHyprland = base;
  notHyprland.notShowIn = {QStringLiteral("Hyprland")};
  QTest::newRow("not shown here") << notHyprland << false;

  auto notKde = base;
  notKde.notShowIn = {QStringLiteral("KDE")};
  QTest::newRow("not shown elsewhere") << notKde << true;
}

void DesktopEntryTest::filtersVisibility() {
  QFETCH(DesktopEntry, entry);
  QFETCH(bool, shown);
  QCOMPARE(entry.isShownIn({QStringLiteral("Hyprland")}), shown);
}

QTEST_GUILESS_MAIN(DesktopEntryTest)
#include "desktopentry_test.moc"
