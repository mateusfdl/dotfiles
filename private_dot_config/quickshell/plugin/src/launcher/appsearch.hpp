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

class AppSearchBackend : public QObject {
  Q_OBJECT
  QML_ELEMENT
  QML_SINGLETON

  Q_PROPERTY(
      QVariantList applications READ applications NOTIFY applicationsChanged)
  Q_PROPERTY(bool sloppySearch READ sloppySearch WRITE setSloppySearch NOTIFY
                 sloppySearchChanged)
  Q_PROPERTY(qreal scoreThreshold READ scoreThreshold WRITE setScoreThreshold
                 NOTIFY scoreThresholdChanged)

public:
  explicit AppSearchBackend(QObject *parent = nullptr);

  [[nodiscard]] QVariantList applications() const;
  [[nodiscard]] bool sloppySearch() const;
  [[nodiscard]] qreal scoreThreshold() const;

  void setSloppySearch(bool value);
  void setScoreThreshold(qreal value);

  Q_INVOKABLE QVariantList search(const QString &query) const;
  Q_INVOKABLE void launch(const QVariantMap &entry) const;
  Q_INVOKABLE QString guessIcon(const QString &str) const;
  Q_INVOKABLE void refresh();

signals:
  void applicationsChanged();
  void sloppySearchChanged();
  void scoreThresholdChanged();

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
