#pragma once

#include "desktopentry.hpp"
#include "desktopfiles.hpp"
#include "pathwatcher.hpp"

#include <QHash>
#include <QIcon>
#include <QObject>
#include <QRegularExpression>
#include <QString>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>

#include <functional>
#include <string>
#include <vector>

class AppSearch : public QObject {
  Q_OBJECT
  QML_ELEMENT
  QML_SINGLETON

  Q_PROPERTY(
      QVariantList applications READ applications NOTIFY applicationsChanged)
  Q_PROPERTY(QVariantList quickshellApps READ quickshellApps CONSTANT)

public:
  using Reader = std::function<std::string(const std::string &)>;

  explicit AppSearch(QObject *parent = nullptr);
  explicit AppSearch(std::vector<std::string> applicationDirs,
                     PathWatcher::Resolver resolver, PathWatcher::Timing timing,
                     Reader reader, QObject *parent);

  [[nodiscard]] QVariantList applications() const;
  [[nodiscard]] QVariantList quickshellApps() const;

  Q_INVOKABLE QVariantList search(const QString &query) const;
  Q_INVOKABLE void launch(const QVariantMap &entry);
  Q_INVOKABLE QString guessIcon(const QString &str) const;
  Q_INVOKABLE void refresh();

signals:
  void applicationsChanged();
  void actionRequested(const QString &action);

private:
  friend class AppSearchTest;

  struct DesktopApp {
    QString id;
    QString name;
    QString icon;
    QString comment;
    QString exec;
    QString path;
    QString category;
    bool terminal{false};

    friend bool operator==(const DesktopApp &, const DesktopApp &) = default;
  };

  struct CachedEntry {
    FileKey key;
    DesktopEntry entry;
  };

  void rewatchAndScan();
  void scanApplications();
  [[nodiscard]] std::vector<DesktopApp>
  loadApplications(const std::vector<DesktopFile> &files);
  void publish(std::vector<DesktopApp> apps);
  [[nodiscard]] QVariantList searchApplications(const QString &query) const;
  [[nodiscard]] static std::vector<std::string> xdgApplicationDirs();
  [[nodiscard]] static DesktopApp toDesktopApp(const QString &id,
                                               const DesktopEntry &entry);
  [[nodiscard]] static QString bucketForCategories(const QStringList &cats);
  [[nodiscard]] static QString
  processExecString(const QString &exec, const QString &name = {},
                    const QString &icon = {}, const QString &desktopFile = {});
  [[nodiscard]] bool iconExists(const QString &iconName) const;

  [[nodiscard]] static const QHash<QString, QString> &iconSubstitutions();
  struct RegexSubstitution {
    QRegularExpression regex;
    QString replacement;
  };
  [[nodiscard]] static const std::vector<RegexSubstitution> &
  regexSubstitutions();

  std::vector<std::string> m_applicationDirs;
  QStringList m_currentDesktops;
  Reader m_reader;
  std::vector<CachedEntry> m_entryCache;
  std::vector<DesktopApp> m_apps;
  QVariantList m_applicationsCache;
  QVariantList m_searchTargets;

  PathWatcher m_watcher;
};
