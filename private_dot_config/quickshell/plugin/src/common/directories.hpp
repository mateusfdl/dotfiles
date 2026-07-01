#pragma once

#include <QObject>
#include <QString>
#include <QtQml/qqmlregistration.h>

class Directories : public QObject {
  Q_OBJECT
  QML_ELEMENT
  QML_SINGLETON
  Q_PROPERTY(QString home READ home CONSTANT)
  Q_PROPERTY(QString config READ config CONSTANT)
  Q_PROPERTY(QString state READ state CONSTANT)
  Q_PROPERTY(QString pictures READ pictures CONSTANT)
  Q_PROPERTY(QString shellConfig READ shellConfig CONSTANT)
  Q_PROPERTY(QString shellConfigPath READ shellConfigPath CONSTANT)
  Q_PROPERTY(
      QString currentWallpaperScriptPath READ currentWallpaperScriptPath CONSTANT)

public:
  explicit Directories(QObject *parent = nullptr);

  QString home() const { return m_home; }
  QString config() const { return m_config; }
  QString state() const { return m_state; }
  QString pictures() const { return m_pictures; }
  QString shellConfig() const { return m_shellConfig; }
  QString shellConfigPath() const { return m_shellConfigPath; }
  QString currentWallpaperScriptPath() const {
    return m_currentWallpaperScriptPath;
  }

private:
  QString m_home;
  QString m_config;
  QString m_state;
  QString m_pictures;
  QString m_shellConfig;
  QString m_shellConfigPath;
  QString m_currentWallpaperScriptPath;
};
