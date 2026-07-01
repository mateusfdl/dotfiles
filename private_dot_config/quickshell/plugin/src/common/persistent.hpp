#pragma once

#include <QObject>
#include <QString>
#include <QtQml/qqmlregistration.h>

class Persistent : public QObject {
  Q_OBJECT
  QML_ELEMENT
  QML_SINGLETON
  Q_PROPERTY(bool ready READ ready NOTIFY readyChanged)
  Q_PROPERTY(bool isNewHyprlandInstance READ isNewHyprlandInstance NOTIFY
                 isNewHyprlandInstanceChanged)

public:
  explicit Persistent(QObject *parent = nullptr);

  bool ready() const { return m_ready; }
  bool isNewHyprlandInstance() const { return m_isNewHyprlandInstance; }

signals:
  void readyChanged();
  void isNewHyprlandInstanceChanged();

private:
  void initialize();
  static QString statesFilePath();

  bool m_ready = false;
  bool m_isNewHyprlandInstance = false;
};
