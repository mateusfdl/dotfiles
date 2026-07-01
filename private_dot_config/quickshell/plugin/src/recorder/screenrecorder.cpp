#include "screenrecorder.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QRegularExpression>

#include <signal.h>
#include <sys/types.h>

namespace {
constexpr int STATUS_POLL_MS = 500;
const QString REGION_FILE = QStringLiteral("/tmp/screen_recording.geometry");
const QString PID_FILE = QStringLiteral("/tmp/screen_recording.pid");
} // namespace

ScreenRecorder::ScreenRecorder(QObject *parent)
    : QObject(parent),
      m_recordScript(QDir::homePath() +
                     QStringLiteral("/scripts/record_current_monitor")) {
  connect(&m_toggleProcess, &QProcess::finished, this,
          [this] { checkStatus(); });

  m_statusTimer.setInterval(STATUS_POLL_MS);
  connect(&m_statusTimer, &QTimer::timeout, this, &ScreenRecorder::checkStatus);
  m_statusTimer.start();

  connect(&m_regionWatcher, &QFileSystemWatcher::fileChanged, this,
          [this] { loadRegion(); });

  checkStatus();
}

void ScreenRecorder::toggle() {
  if (m_toggleProcess.state() != QProcess::NotRunning)
    return;
  m_toggleProcess.start(m_recordScript, {QStringLiteral("toggle")});
}

void ScreenRecorder::checkStatus() {
  bool recording = false;

  QFile pidFile(PID_FILE);
  if (pidFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
    bool ok = false;
    const qint64 pid = pidFile.readAll().trimmed().toLongLong(&ok);
    if (ok && pid > 0 && ::kill(static_cast<pid_t>(pid), 0) == 0)
      recording = true;
  }

  setRecording(recording);
  if (recording && !m_hasRegion)
    loadRegion();
}

void ScreenRecorder::setRecording(bool recording) {
  if (m_isRecording == recording)
    return;
  m_isRecording = recording;
  emit isRecordingChanged();

  if (recording)
    loadRegion();
  else
    clearRegion();
}

void ScreenRecorder::loadRegion() {
  QFile file(REGION_FILE);
  if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
    clearRegion();
    return;
  }
  const QString text = QString::fromUtf8(file.readAll()).trimmed();
  file.close();

  if (!m_regionWatcher.files().contains(REGION_FILE))
    m_regionWatcher.addPath(REGION_FILE);

  static const QRegularExpression pattern(
      QStringLiteral("^(-?\\d+),(-?\\d+)\\s+(\\d+)x(\\d+)$"));
  const auto match = pattern.match(text);
  if (!match.hasMatch()) {
    clearRegion();
    return;
  }

  m_regionX = match.captured(1).toInt();
  m_regionY = match.captured(2).toInt();
  m_regionWidth = match.captured(3).toInt();
  m_regionHeight = match.captured(4).toInt();
  m_hasRegion = true;
  emit regionChanged();
}

void ScreenRecorder::clearRegion() {
  if (!m_hasRegion)
    return;
  m_hasRegion = false;
  emit regionChanged();
}
