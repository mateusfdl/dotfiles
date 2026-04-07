#include "appsearch.hpp"
#include "fuzzysort.hpp"
#include "levendist.hpp"

#include <QDir>
#include <QDirIterator>
#include <QFileInfo>
#include <QIcon>
#include <QProcess>
#include <QSettings>
#include <QStandardPaths>

#include <algorithm>
#include <set>

AppSearchBackend::AppSearchBackend(QObject *parent) : QObject(parent) {
  m_refreshDebounce.setSingleShot(true);
  m_refreshDebounce.setInterval(500);
  connect(&m_refreshDebounce, &QTimer::timeout, this,
          &AppSearchBackend::refresh);

  connect(&m_watcher, &QFileSystemWatcher::directoryChanged, this,
          [this]() { m_refreshDebounce.start(); });

  scanApplications();
}

QVariantList AppSearchBackend::applications() const {
  return m_applicationsCache;
}

bool AppSearchBackend::sloppySearch() const { return m_sloppySearch; }

qreal AppSearchBackend::scoreThreshold() const { return m_scoreThreshold; }

void AppSearchBackend::setSloppySearch(bool value) {
  if (m_sloppySearch != value) {
    m_sloppySearch = value;
    emit sloppySearchChanged();
  }
}

void AppSearchBackend::setScoreThreshold(qreal value) {
  if (!qFuzzyCompare(m_scoreThreshold, value)) {
    m_scoreThreshold = value;
    emit scoreThresholdChanged();
  }
}

QStringList AppSearchBackend::xdgDataDirs() {
  QStringList dirs;

  const QString localShare =
      QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation);
  if (!localShare.isEmpty()) {
    dirs << localShare + QStringLiteral("/applications");
  }

  QByteArray xdgDirs = qgetenv("XDG_DATA_DIRS");
  if (xdgDirs.isEmpty()) {
    xdgDirs = "/usr/local/share:/usr/share";
  }

  const auto parts =
      QString::fromUtf8(xdgDirs).split(QLatin1Char(':'), Qt::SkipEmptyParts);
  for (const auto &dir : parts) {
    dirs << dir + QStringLiteral("/applications");
  }

  const QString flatpakExports =
      QDir::homePath() +
      QStringLiteral("/.local/share/flatpak/exports/share/applications");
  if (QDir(flatpakExports).exists()) {
    dirs << flatpakExports;
  }

  const QString systemFlatpak =
      QStringLiteral("/var/lib/flatpak/exports/share/applications");
  if (QDir(systemFlatpak).exists()) {
    dirs << systemFlatpak;
  }

  const QString snapApps =
      QStringLiteral("/var/lib/snapd/desktop/applications");
  if (QDir(snapApps).exists()) {
    dirs << snapApps;
  }

  return dirs;
}

std::optional<AppSearchBackend::DesktopApp>
AppSearchBackend::parseDesktopFile(const QString &filePath) {
  QSettings ini(filePath, QSettings::IniFormat);
  ini.beginGroup(QStringLiteral("Desktop Entry"));

  const QString type = ini.value(QStringLiteral("Type"), QString()).toString();
  if (type != QStringLiteral("Application")) {
    return std::nullopt;
  }

  if (ini.value(QStringLiteral("Hidden"), false).toBool()) {
    return std::nullopt;
  }
  if (ini.value(QStringLiteral("NoDisplay"), false).toBool()) {
    return std::nullopt;
  }

  const QString name = ini.value(QStringLiteral("Name"), QString()).toString();
  const QString exec = ini.value(QStringLiteral("Exec"), QString()).toString();

  if (name.isEmpty() || exec.isEmpty()) {
    return std::nullopt;
  }

  const QString currentDesktop =
      QString::fromUtf8(qgetenv("XDG_CURRENT_DESKTOP"));
  const QStringList currentDesktops =
      currentDesktop.split(QLatin1Char(':'), Qt::SkipEmptyParts);

  const QString onlyShowIn =
      ini.value(QStringLiteral("OnlyShowIn"), QString()).toString();
  if (!onlyShowIn.isEmpty()) {
    const auto allowed = onlyShowIn.split(QLatin1Char(';'), Qt::SkipEmptyParts);
    bool found = false;
    for (const auto &de : currentDesktops) {
      if (allowed.contains(de, Qt::CaseInsensitive)) {
        found = true;
        break;
      }
    }
    if (!found) {
      return std::nullopt;
    }
  }

  const QString notShowIn =
      ini.value(QStringLiteral("NotShowIn"), QString()).toString();
  if (!notShowIn.isEmpty()) {
    const auto denied = notShowIn.split(QLatin1Char(';'), Qt::SkipEmptyParts);
    for (const auto &de : currentDesktops) {
      if (denied.contains(de, Qt::CaseInsensitive)) {
        return std::nullopt;
      }
    }
  }

  DesktopApp app;
  app.id = QFileInfo(filePath).completeBaseName();
  app.name = name;
  app.icon = ini.value(QStringLiteral("Icon"), QString()).toString();
  app.comment = ini.value(QStringLiteral("Comment"), QString()).toString();
  app.exec = exec;
  app.path = ini.value(QStringLiteral("Path"), QString()).toString();
  app.terminal = ini.value(QStringLiteral("Terminal"), false).toBool();

  return app;
}

QString AppSearchBackend::processExecString(const QString &exec,
                                            const QString &name,
                                            const QString &icon,
                                            const QString &desktopFile) {
  QString result = exec;

  result.remove(QStringLiteral("%f"));
  result.remove(QStringLiteral("%F"));
  result.remove(QStringLiteral("%u"));
  result.remove(QStringLiteral("%U"));
  result.remove(QStringLiteral("%d"));
  result.remove(QStringLiteral("%D"));
  result.remove(QStringLiteral("%n"));
  result.remove(QStringLiteral("%N"));
  result.remove(QStringLiteral("%v"));
  result.remove(QStringLiteral("%m"));

  if (!icon.isEmpty()) {
    result.replace(QStringLiteral("%i"), QStringLiteral("--icon ") + icon);
  } else {
    result.remove(QStringLiteral("%i"));
  }

  result.replace(QStringLiteral("%c"), name);
  result.replace(QStringLiteral("%k"), desktopFile);
  result.replace(QStringLiteral("%%"), QStringLiteral("%"));

  return result.simplified();
}

bool AppSearchBackend::iconExists(const QString &iconName) const {
  if (iconName.isEmpty() || iconName == QStringLiteral("image-missing")) {
    return false;
  }

  if (iconName.startsWith(QLatin1Char('/'))) {
    return QFileInfo::exists(iconName);
  }

  return QIcon::hasThemeIcon(iconName);
}

const QHash<QString, QString> &AppSearchBackend::iconSubstitutions() {
  static const QHash<QString, QString> subs = {
      {QStringLiteral("code-url-handler"),
       QStringLiteral("visual-studio-code")},
      {QStringLiteral("Code"), QStringLiteral("visual-studio-code")},
      {QStringLiteral("gnome-tweaks"), QStringLiteral("org.gnome.tweaks")},
      {QStringLiteral("pavucontrol-qt"), QStringLiteral("pavucontrol")},
      {QStringLiteral("wps"), QStringLiteral("wps-office2019-kprometheus")},
      {QStringLiteral("wpsoffice"),
       QStringLiteral("wps-office2019-kprometheus")},
      {QStringLiteral("footclient"), QStringLiteral("foot")},
      {QStringLiteral("zen"), QStringLiteral("zen-browser")},
  };
  return subs;
}

const std::vector<AppSearchBackend::RegexSubstitution> &
AppSearchBackend::regexSubstitutions() {
  static const std::vector<RegexSubstitution> subs = {
      {QRegularExpression(QStringLiteral("^steam_app_(\\d+)$")),
       QStringLiteral("steam_icon_\\1")},
      {QRegularExpression(QStringLiteral("Minecraft.*")),
       QStringLiteral("minecraft")},
      {QRegularExpression(QStringLiteral(".*polkit.*")),
       QStringLiteral("system-lock-screen")},
      {QRegularExpression(QStringLiteral("gcr.prompter")),
       QStringLiteral("system-lock-screen")},
  };
  return subs;
}

QString AppSearchBackend::guessIcon(const QString &str) const {
  if (str.isEmpty()) {
    return QStringLiteral("image-missing");
  }

  const auto &subs = iconSubstitutions();
  auto it = subs.constFind(str);
  if (it != subs.constEnd()) {
    return it.value();
  }

  for (const auto &rsub : regexSubstitutions()) {
    auto match = rsub.regex.match(str);
    if (match.hasMatch()) {
      QString replaced = str;
      replaced.replace(rsub.regex, rsub.replacement);
      if (replaced != str) {
        return replaced;
      }
    }
  }

  if (iconExists(str)) {
    return str;
  }

  {
    const auto parts = str.split(QLatin1Char('.'));
    if (parts.size() > 1) {
      const QString lastPart = parts.last().toLower();
      if (iconExists(lastPart)) {
        return lastPart;
      }
    }
  }

  {
    QString hyphenated = str.toLower();
    hyphenated.replace(QRegularExpression(QStringLiteral("\\s+")),
                       QStringLiteral("-"));
    if (iconExists(hyphenated)) {
      return hyphenated;
    }
  }

  {
    const auto results = search(str);
    if (!results.isEmpty()) {
      const auto first = results.first().toMap();
      const QString icon = first.value(QStringLiteral("icon")).toString();
      if (iconExists(icon)) {
        return icon;
      }
    }
  }

  return str;
}

void AppSearchBackend::scanApplications() {
  m_apps.clear();
  m_applicationsCache.clear();

  const auto watched = m_watcher.directories();
  if (!watched.isEmpty()) {
    m_watcher.removePaths(watched);
  }

  std::set<QString> seenIds;
  const auto dirs = xdgDataDirs();

  for (const auto &dirPath : dirs) {
    QDir dir(dirPath);
    if (!dir.exists()) {
      continue;
    }

    m_watcher.addPath(dirPath);

    QDirIterator it(dirPath, {QStringLiteral("*.desktop")}, QDir::Files,
                    QDirIterator::Subdirectories);
    while (it.hasNext()) {
      const QString filePath = it.next();
      auto maybeApp = parseDesktopFile(filePath);
      if (!maybeApp.has_value()) {
        continue;
      }

      auto &app = maybeApp.value();

      if (seenIds.contains(app.id)) {
        continue;
      }
      seenIds.insert(app.id);

      m_apps.push_back(PreparedApp{
          .app = std::move(app),
          .prepared = {},
      });
    }
  }

  std::sort(m_apps.begin(), m_apps.end(),
            [](const PreparedApp &a, const PreparedApp &b) {
              return QString::localeAwareCompare(a.app.name, b.app.name) < 0;
            });

  for (auto &pa : m_apps) {
    pa.prepared = FuzzySort::prepare(pa.app.name + QStringLiteral(" "));

    QVariantMap entry;
    entry[QStringLiteral("id")] = pa.app.id;
    entry[QStringLiteral("name")] = pa.app.name;
    entry[QStringLiteral("icon")] = pa.app.icon;
    entry[QStringLiteral("comment")] = pa.app.comment;
    entry[QStringLiteral("exec")] = pa.app.exec;
    entry[QStringLiteral("path")] = pa.app.path;
    entry[QStringLiteral("terminal")] = pa.app.terminal;

    m_applicationsCache.append(QVariant::fromValue(entry));
  }

  emit applicationsChanged();
}

void AppSearchBackend::refresh() { scanApplications(); }

QVariantList AppSearchBackend::search(const QString &query) const {
  if (query.isEmpty()) {
    return m_applicationsCache;
  }

  const QString queryLower = query.toLower();

  if (m_sloppySearch) {
    struct ScoredApp {
      qreal score;
      int index;
    };

    std::vector<ScoredApp> scored;
    scored.reserve(m_apps.size());

    for (int i = 0; i < static_cast<int>(m_apps.size()); ++i) {
      const qreal score =
          Levendist::computeScore(m_apps[i].app.name.toLower(), queryLower);
      if (score > m_scoreThreshold) {
        scored.push_back({score, i});
      }
    }

    std::sort(scored.begin(), scored.end(),
              [](const ScoredApp &a, const ScoredApp &b) {
                return a.score > b.score;
              });

    QVariantList results;
    results.reserve(static_cast<int>(scored.size()));
    for (const auto &s : scored) {
      results.append(m_applicationsCache.at(s.index));
    }
    return results;

  } else {
    QVariantList targets;
    targets.reserve(static_cast<int>(m_apps.size()));

    for (const auto &pa : m_apps) {
      QVariantMap item;
      item[QStringLiteral("name")] = pa.prepared;
      item[QStringLiteral("entry")] = pa.app.id;
      targets.append(QVariant::fromValue(item));
    }

    QVariantMap options;
    options[QStringLiteral("all")] = true;
    options[QStringLiteral("key")] = QStringLiteral("name");

    const auto fuzzyResults = FuzzySort::go(query, targets, options);

    QHash<QString, int> idToIndex;
    idToIndex.reserve(static_cast<int>(m_apps.size()));
    for (int i = 0; i < static_cast<int>(m_apps.size()); ++i) {
      idToIndex[m_apps[i].app.id] = i;
    }

    QVariantList results;
    results.reserve(fuzzyResults.size());
    for (const auto &r : fuzzyResults) {
      const auto rMap = r.toMap();
      const auto obj = rMap.value(QStringLiteral("obj")).toMap();
      const QString id = obj.value(QStringLiteral("entry")).toString();
      auto idxIt = idToIndex.constFind(id);
      if (idxIt != idToIndex.constEnd()) {
        results.append(m_applicationsCache.at(idxIt.value()));
      }
    }
    return results;
  }
}

void AppSearchBackend::launch(const QVariantMap &entry) const {
  const QString exec = entry.value(QStringLiteral("exec")).toString();
  if (exec.isEmpty()) {
    return;
  }

  const QString name = entry.value(QStringLiteral("name")).toString();
  const QString icon = entry.value(QStringLiteral("icon")).toString();
  const QString id = entry.value(QStringLiteral("id")).toString();
  const QString workDir = entry.value(QStringLiteral("path")).toString();
  const bool terminal = entry.value(QStringLiteral("terminal"), false).toBool();

  QString processed = processExecString(exec, name, icon, id);

  if (terminal) {
    const QStringList terminalCandidates = {
        QStringLiteral("foot"),           QStringLiteral("kitty"),
        QStringLiteral("alacritty"),      QStringLiteral("wezterm"),
        QStringLiteral("xterm"),          QStringLiteral("konsole"),
        QStringLiteral("gnome-terminal"),
    };

    QString termBin;
    const QString envTerminal = QString::fromUtf8(qgetenv("TERMINAL"));
    if (!envTerminal.isEmpty()) {
      termBin = envTerminal;
    } else {
      for (const auto &t : terminalCandidates) {
        const QString path = QStandardPaths::findExecutable(t);
        if (!path.isEmpty()) {
          termBin = path;
          break;
        }
      }
    }

    if (!termBin.isEmpty()) {
      processed = termBin + QStringLiteral(" -e ") + processed;
    }
  }

  QProcess::startDetached(QStringLiteral("/bin/sh"),
                          {QStringLiteral("-c"), processed}, workDir);
}
