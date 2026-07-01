#include "persistent.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>
#include <QTimer>

namespace {
const QString SIGNATURE_KEY = QStringLiteral("hyprlandInstanceSignature");
} // namespace

Persistent::Persistent(QObject *parent) : QObject(parent) {
  QTimer::singleShot(0, this, &Persistent::initialize);
}

QString Persistent::statesFilePath() {
  return QStandardPaths::writableLocation(QStandardPaths::StateLocation) +
         QStringLiteral("/states.json");
}

void Persistent::initialize() {
  const QString path = statesFilePath();

  QJsonObject states;
  QFile file(path);
  if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
    states = QJsonDocument::fromJson(file.readAll()).object();
    file.close();
  }

  const QString saved = states.value(SIGNATURE_KEY).toString();
  const QString current = qEnvironmentVariable("HYPRLAND_INSTANCE_SIGNATURE");

  m_isNewHyprlandInstance = saved != current;
  emit isNewHyprlandInstanceChanged();

  states.insert(SIGNATURE_KEY, current);
  QDir().mkpath(QFileInfo(path).absolutePath());
  if (file.open(QIODevice::WriteOnly | QIODevice::Text)) {
    file.write(QJsonDocument(states).toJson(QJsonDocument::Compact));
    file.close();
  }

  m_ready = true;
  emit readyChanged();
}
