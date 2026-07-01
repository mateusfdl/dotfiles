#pragma once

#include <QFileSystemWatcher>
#include <QObject>
#include <QProcess>
#include <QString>
#include <QTimer>
#include <QtQml/qqmlregistration.h>

class ScreenRecorder : public QObject {
  Q_OBJECT
  QML_ELEMENT
  QML_SINGLETON
  Q_PROPERTY(bool isRecording READ isRecording NOTIFY isRecordingChanged)
  Q_PROPERTY(bool hasRegion READ hasRegion NOTIFY regionChanged)
  Q_PROPERTY(int regionX READ regionX NOTIFY regionChanged)
  Q_PROPERTY(int regionY READ regionY NOTIFY regionChanged)
  Q_PROPERTY(int regionWidth READ regionWidth NOTIFY regionChanged)
  Q_PROPERTY(int regionHeight READ regionHeight NOTIFY regionChanged)

public:
  explicit ScreenRecorder(QObject *parent = nullptr);

  bool isRecording() const { return m_isRecording; }
  bool hasRegion() const { return m_hasRegion; }
  int regionX() const { return m_regionX; }
  int regionY() const { return m_regionY; }
  int regionWidth() const { return m_regionWidth; }
  int regionHeight() const { return m_regionHeight; }

  Q_INVOKABLE void toggle();

signals:
  void isRecordingChanged();
  void regionChanged();

private:
  void checkStatus();
  void setRecording(bool recording);
  void loadRegion();
  void clearRegion();

  QString m_recordScript;
  bool m_isRecording{false};
  bool m_hasRegion{false};
  int m_regionX{0};
  int m_regionY{0};
  int m_regionWidth{0};
  int m_regionHeight{0};

  QProcess m_toggleProcess;
  QTimer m_statusTimer;
  QFileSystemWatcher m_regionWatcher;
};
