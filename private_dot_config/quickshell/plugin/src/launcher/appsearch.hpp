#pragma once

#include <QFileSystemWatcher>
#include <QIcon>
#include <QObject>
#include <QRegularExpression>
#include <QString>
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
  Q_PROPERTY(bool sloppySearch READ sloppySearch WRITE setSloppySearch NOTIFY
                 sloppySearchChanged)

public:
  explicit AppSearch(QObject *parent = nullptr);

  [[nodiscard]] QVariantList applications() const;
  [[nodiscard]] QVariantList quickshellApps() const;
  [[nodiscard]] bool sloppySearch() const;

  void setSloppySearch(bool value);

  Q_INVOKABLE QVariantList search(const QString &query) const;
  Q_INVOKABLE void launch(const QVariantMap &entry);
  Q_INVOKABLE QString guessIcon(const QString &str) const;
  Q_INVOKABLE void refresh();

signals:
  void applicationsChanged();
  void sloppySearchChanged();
  void actionRequested(const QString &action);

private:
  struct DesktopApp {
    QString id;
    QString name;
    QString icon;
    QString comment;
    QString exec;
    QString path;
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
  bool m_sloppySearch{false};
  qreal m_scoreThreshold{0.2};

  QFileSystemWatcher m_watcher;
  QTimer m_refreshDebounce;
};
