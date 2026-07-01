#include "directories.hpp"

#include <QDir>
#include <QStandardPaths>

Directories::Directories(QObject *parent)
    : QObject(parent),
      m_home(QStandardPaths::writableLocation(QStandardPaths::HomeLocation)),
      m_config(
          QStandardPaths::writableLocation(QStandardPaths::ConfigLocation)),
      m_state(QStandardPaths::writableLocation(QStandardPaths::StateLocation)),
      m_pictures(
          QStandardPaths::writableLocation(QStandardPaths::PicturesLocation)),
      m_shellConfig(m_config + QStringLiteral("/quickshell")),
      m_shellConfigPath(m_shellConfig + QStringLiteral("/config.json")),
      m_currentWallpaperScriptPath(
          m_home + QStringLiteral("/scripts/current_wallpaper")) {
  QDir().mkpath(m_shellConfig);
}
