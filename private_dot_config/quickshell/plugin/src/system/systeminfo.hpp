#pragma once

#include <QObject>
#include <QString>
#include <QTimer>
#include <QtQml/qqmlregistration.h>

class SystemInfo : public QObject {
  Q_OBJECT
  QML_ELEMENT
  QML_SINGLETON
  Q_PROPERTY(QString username READ username CONSTANT)
  Q_PROPERTY(QString uptime READ uptime NOTIFY uptimeChanged)

public:
  explicit SystemInfo(QObject *parent = nullptr);

  QString username() const { return m_username; }
  QString uptime() const { return m_uptime; }

signals:
  void uptimeChanged();

private:
  void refreshUptime();
  static QString resolveUsername();
  static QString formatUptime(qint64 seconds);

  QString m_username;
  QString m_uptime;
  QTimer m_uptimeTimer;
};
