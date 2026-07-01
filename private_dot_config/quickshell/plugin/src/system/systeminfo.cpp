#include "systeminfo.hpp"

#include <QByteArray>
#include <QFile>
#include <QStringList>

#include <pwd.h>
#include <unistd.h>

namespace {
constexpr int UPTIME_REFRESH_MS = 60000;
}

SystemInfo::SystemInfo(QObject *parent)
    : QObject(parent), m_username(resolveUsername()) {
  connect(&m_uptimeTimer, &QTimer::timeout, this, &SystemInfo::refreshUptime);
  m_uptimeTimer.setInterval(UPTIME_REFRESH_MS);
  m_uptimeTimer.start();
  refreshUptime();
}

QString SystemInfo::resolveUsername() {
  if (const passwd *pw = getpwuid(getuid()); pw && pw->pw_name)
    return QString::fromLocal8Bit(pw->pw_name);
  const QString envUser = qEnvironmentVariable("USER");
  return envUser.isEmpty() ? QStringLiteral("user") : envUser;
}

void SystemInfo::refreshUptime() {
  QFile file(QStringLiteral("/proc/uptime"));
  if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
    return;
  const QByteArray firstField = file.readLine().split(' ').value(0).trimmed();

  bool ok = false;
  const auto seconds = static_cast<qint64>(firstField.toDouble(&ok));
  if (!ok)
    return;

  const QString formatted = formatUptime(seconds);
  if (formatted == m_uptime)
    return;
  m_uptime = formatted;
  emit uptimeChanged();
}

QString SystemInfo::formatUptime(qint64 seconds) {
  if (seconds < 60)
    return QStringLiteral("less than a minute");

  const qint64 days = seconds / 86400;
  const qint64 hours = (seconds % 86400) / 3600;
  const qint64 mins = (seconds % 3600) / 60;

  QStringList parts;
  if (days > 0)
    parts << QStringLiteral("%1d").arg(days);
  if (hours > 0)
    parts << QStringLiteral("%1h").arg(hours);
  if (mins > 0 || parts.isEmpty())
    parts << QStringLiteral("%1m").arg(mins);

  return parts.join(QLatin1Char(' '));
}
