#pragma once

#include <QFileSystemWatcher>
#include <QIcon>
#include <QObject>
#include <QRegularExpression>
#include <QString>
#include <QStringList>
#include <QTimer>
#include <QVariantList>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>

#include <vector>

class AppSearch : public QObject {
  Q_OBJECT
  QML_ELEMENT
  QML_SINGLETON

  Q_PROPERTY(
      QVariantList applications READ applications NOTIFY applicationsChanged)
  Q_PROPERTY(QVariantList quickshellApps READ quickshellApps CONSTANT)

public:
  explicit AppSearch(QObject *parent = nullptr);

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
  struct DesktopApp {
    QString id;
    QString name;
    QString icon;
    QString comment;
    QString exec;
    QString path;
    QString category;
    bool terminal{false};
  };

  struct PreparedApp {
    DesktopApp app;
    QVariantMap prepared;
  };

  void scanApplications();
  [[nodiscard]] QVariantList searchApplications(const QString &query) const;
  [[nodiscard]] static QStringList xdgDataDirs();
  [[nodiscard]] static std::optional<DesktopApp>
  parseDesktopFile(const QString &filePath);
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

  std::vector<PreparedApp> m_apps;
  QVariantList m_applicationsCache;

  QFileSystemWatcher m_watcher;
  QTimer m_refreshDebounce;
};
