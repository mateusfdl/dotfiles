#include "appsearch.hpp"
#include "desktopentry.hpp"
#include "desktopfiles.hpp"
#include "fuzzysort.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QIcon>
#include <QProcess>
#include <QSet>
#include <QStandardPaths>

#include <algorithm>
#include <chrono>
#include <span>
#include <string_view>
#include <utility>

namespace {

constexpr std::string_view NIX_STORE = "/nix/store";
constexpr std::string_view DESKTOP_SUFFIX = ".desktop";
constexpr PathWatcher::Timing WATCH_TIMING{
    .quiet = std::chrono::milliseconds(100),
    .maxWait = std::chrono::milliseconds(1000),
};

std::vector<WatchPoint> resolveOutsideNixStore(
    std::span<const std::string> paths) {
  return resolveWatchPoints(paths, NIX_STORE);
}

} // namespace

AppSearch::AppSearch(QObject *parent)
    : AppSearch(xdgApplicationDirs(), resolveOutsideNixStore, WATCH_TIMING,
                readDesktopFile, parent) {}

AppSearch::AppSearch(std::vector<std::string> applicationDirs,
                     PathWatcher::Resolver resolver, PathWatcher::Timing timing,
                     Reader reader, QObject *parent)
    : QObject(parent), m_applicationDirs(std::move(applicationDirs)),
      m_currentDesktops(QString::fromUtf8(qgetenv("XDG_CURRENT_DESKTOP"))
                            .split(QLatin1Char(':'), Qt::SkipEmptyParts)),
      m_reader(std::move(reader)), m_watcher(std::move(resolver), timing) {
  connect(&m_watcher, &PathWatcher::changed, this, &AppSearch::rewatchAndScan);
  rewatchAndScan();
}

QVariantList AppSearch::applications() const {
  return m_applicationsCache;
}

QVariantList AppSearch::quickshellApps() const {
  const auto entry = [](const char *name, const char *icon, const char *comment,
                        const char *field, const char *value) {
    return QVariantMap{
        {QStringLiteral("name"), QString::fromUtf8(name)},
        {QStringLiteral("icon"), QString::fromUtf8(icon)},
        {QStringLiteral("comment"), QString::fromUtf8(comment)},
        {QString::fromUtf8(field), QString::fromUtf8(value)},
    };
  };

  static const QVariantList apps = {
      entry("Wallpaper Selector", "preferences-desktop-wallpaper",
            "Change your wallpaper", "action", "wallpaperSelector"),
      entry("Overview", "view-grid", "Open overview mode", "action",
            "overview"),
      entry("SoundCloud", "soundcloud", "Listen to music on SoundCloud", "exec",
            "soundcloud"),
      entry("Spotify", "spotify", "Music streaming", "exec", "spotify"),
      entry("Obsidian", "obsidian", "Knowledge base and notes", "exec",
            "obsidian"),
      entry("Brave", "brave-browser", "Web browser", "exec", "brave"),
      entry("Discord", "discord", "Chat and voice", "exec", "discord"),
      entry("Morgen", "morgen", "Calendar and scheduling", "exec", "morgen"),
      entry("Dofus", "zaap", "Play Dofus through Ankama Launcher", "exec",
            "ankama-launcher"),
      entry("Ankama Launcher", "zaap", "Ankama portal and game launcher",
            "exec", "ankama-launcher"),
      entry("Unity Hub", "unityhub", "Unity editor and project manager", "exec",
            "unityhub"),
  };
  return apps;
}

std::vector<std::string> AppSearch::xdgApplicationDirs() {
  std::vector<std::string> dirs;

  const QString localShare =
      QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation);
  if (!localShare.isEmpty()) {
    dirs.push_back(QFile::encodeName(localShare).toStdString() +
                   "/applications");
  }

  QByteArray xdgDirs = qgetenv("XDG_DATA_DIRS");
  if (xdgDirs.isEmpty()) {
    xdgDirs = "/usr/local/share:/usr/share";
  }

  for (const auto &dir : xdgDirs.split(':')) {
    if (!dir.isEmpty()) {
      dirs.push_back(dir.toStdString() + "/applications");
    }
  }

  const std::string optionalDirs[] = {
      QFile::encodeName(QDir::homePath()).toStdString() +
          "/.local/share/flatpak/exports/share/applications",
      "/var/lib/flatpak/exports/share/applications",
      "/var/lib/snapd/desktop/applications",
  };
  for (const auto &dir : optionalDirs) {
    if (QDir(QFile::decodeName(QByteArray::fromStdString(dir))).exists()) {
      dirs.push_back(dir);
    }
  }

  return dirs;
}

AppSearch::DesktopApp AppSearch::toDesktopApp(const QString &id,
                                              const DesktopEntry &entry) {
  return DesktopApp{
      .id = id,
      .name = entry.name,
      .icon = entry.icon,
      .comment = entry.comment,
      .exec = entry.exec,
      .path = entry.path,
      .category = bucketForCategories(entry.categories),
      .terminal = entry.terminal,
  };
}

QString AppSearch::bucketForCategories(const QStringList &cats) {
  static const std::vector<std::pair<QString, QStringList>> buckets = {
      {QStringLiteral("Developer Tools"), {QStringLiteral("Development")}},
      {QStringLiteral("Productivity & Finance"),
       {QStringLiteral("Office"), QStringLiteral("Finance")}},
      {QStringLiteral("Utilities"),
       {QStringLiteral("Utility"), QStringLiteral("System"),
        QStringLiteral("Settings"), QStringLiteral("Accessibility")}},
      {QStringLiteral("Entertainment"),
       {QStringLiteral("AudioVideo"), QStringLiteral("Audio"),
        QStringLiteral("Video"), QStringLiteral("Game"),
        QStringLiteral("Player"), QStringLiteral("TV")}},
      {QStringLiteral("Creativity"),
       {QStringLiteral("Graphics"), QStringLiteral("Photography")}},
      {QStringLiteral("Social"),
       {QStringLiteral("Network"), QStringLiteral("InstantMessaging"),
        QStringLiteral("Chat"), QStringLiteral("Email")}},
  };

  for (const auto &[label, matches] : buckets) {
    for (const auto &cat : cats) {
      if (matches.contains(cat, Qt::CaseInsensitive)) {
        return label;
      }
    }
  }
  return QStringLiteral("Other");
}

QString AppSearch::processExecString(const QString &exec,
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

bool AppSearch::iconExists(const QString &iconName) const {
  if (iconName.isEmpty() || iconName == QStringLiteral("image-missing")) {
    return false;
  }

  if (iconName.startsWith(QLatin1Char('/'))) {
    return QFileInfo::exists(iconName);
  }

  return QIcon::hasThemeIcon(iconName);
}

const QHash<QString, QString> &AppSearch::iconSubstitutions() {
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

const std::vector<AppSearch::RegexSubstitution> &
AppSearch::regexSubstitutions() {
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

QString AppSearch::guessIcon(const QString &str) const {
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
    const auto results = searchApplications(str);
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

void AppSearch::scanApplications() {
  auto apps = loadApplications(listDesktopFiles(m_applicationDirs));
  std::ranges::stable_sort(apps, [](const DesktopApp &a, const DesktopApp &b) {
    return QString::localeAwareCompare(a.name, b.name) < 0;
  });
  if (apps != m_apps) {
    publish(std::move(apps));
  }
}

std::vector<AppSearch::DesktopApp>
AppSearch::loadApplications(const std::vector<DesktopFile> &files) {
  std::vector<CachedEntry> nextCache;
  nextCache.reserve(files.size());
  std::vector<DesktopApp> apps;
  apps.reserve(files.size());
  for (const auto &file : files) {
    const auto cached =
        std::ranges::lower_bound(m_entryCache, file.key, {}, &CachedEntry::key);
    const bool hit = cached != m_entryCache.end() && cached->key == file.key;
    try {
      nextCache.push_back({.key = file.key,
                           .entry = hit ? cached->entry
                                        : DesktopEntry::parse(m_reader(file.path))});
    } catch (const DesktopFileReadError &error) {
      qWarning() << "[AppSearch]" << error.what();
      continue;
    }
    if (nextCache.back().entry.isShownIn(m_currentDesktops)) {
      apps.push_back(toDesktopApp(file.id, nextCache.back().entry));
    }
  }

  std::ranges::sort(nextCache, {}, &CachedEntry::key);
  const auto duplicates = std::ranges::unique(nextCache, {}, &CachedEntry::key);
  nextCache.erase(duplicates.begin(), duplicates.end());
  m_entryCache = std::move(nextCache);
  return apps;
}

void AppSearch::publish(std::vector<DesktopApp> apps) {
  m_applicationsCache.clear();
  m_searchTargets.clear();
  m_applicationsCache.reserve(static_cast<qsizetype>(apps.size()));
  m_searchTargets.reserve(static_cast<qsizetype>(apps.size()));
  for (const auto &app : apps) {
    m_applicationsCache.append(QVariantMap{
        {QStringLiteral("id"), app.id},
        {QStringLiteral("name"), app.name},
        {QStringLiteral("icon"), app.icon},
        {QStringLiteral("comment"), app.comment},
        {QStringLiteral("exec"), app.exec},
        {QStringLiteral("path"), app.path},
        {QStringLiteral("category"), app.category},
        {QStringLiteral("terminal"), app.terminal},
    });
    m_searchTargets.append(QVariantMap{
        {QStringLiteral("name"),
         FuzzySort::prepare(app.name + QStringLiteral(" "))},
        {QStringLiteral("entry"), m_applicationsCache.size() - 1},
    });
  }
  m_apps = std::move(apps);
  emit applicationsChanged();
}

void AppSearch::refresh() { rewatchAndScan(); }

void AppSearch::rewatchAndScan() {
  try {
    m_watcher.watch(m_applicationDirs, DESKTOP_SUFFIX);
  } catch (const PathWatchError &error) {
    qWarning() << "[AppSearch]" << error.what();
  }
  scanApplications();
}

QVariantList AppSearch::search(const QString &query) const {
  const QString queryLower = query.toLower();

  QVariantList quickshellMatches;
  QSet<QString> matchedNames;
  for (const auto &variant : quickshellApps()) {
    const QVariantMap app = variant.toMap();
    const QString name = app.value(QStringLiteral("name")).toString();
    const QString comment = app.value(QStringLiteral("comment")).toString();
    if (name.toLower().contains(queryLower) ||
        comment.toLower().contains(queryLower)) {
      quickshellMatches.append(variant);
      matchedNames.insert(name.toLower());
    }
  }

  QVariantList results = quickshellMatches;
  for (const auto &variant : searchApplications(query)) {
    const QString name =
        variant.toMap().value(QStringLiteral("name")).toString().toLower();
    if (!matchedNames.contains(name)) {
      results.append(variant);
    }
  }
  return results;
}

QVariantList AppSearch::searchApplications(const QString &query) const {
  if (query.isEmpty()) {
    return m_applicationsCache;
  }

  static const QVariantMap options = {
      {QStringLiteral("all"), true},
      {QStringLiteral("key"), QStringLiteral("name")},
  };

  const auto fuzzyResults = FuzzySort::go(query, m_searchTargets, options);

  QVariantList results;
  results.reserve(fuzzyResults.size());
  for (const auto &result : fuzzyResults) {
    const auto index = result.toMap()
                           .value(QStringLiteral("obj"))
                           .toMap()
                           .value(QStringLiteral("entry"))
                           .toInt();
    results.append(m_applicationsCache.at(index));
  }
  return results;
}

void AppSearch::launch(const QVariantMap &entry) {
  const QString action = entry.value(QStringLiteral("action")).toString();
  if (!action.isEmpty()) {
    emit actionRequested(action);
    return;
  }

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
