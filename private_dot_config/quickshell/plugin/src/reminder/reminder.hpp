#pragma once

#include <QObject>
#include <QString>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>

class Reminder : public QObject {
  Q_OBJECT
  QML_ELEMENT
  Q_PROPERTY(QString id READ id WRITE setId NOTIFY idChanged)
  Q_PROPERTY(QString label READ label WRITE setLabel NOTIFY labelChanged)
  Q_PROPERTY(int frequency READ frequency WRITE setFrequency NOTIFY frequencyChanged)
  Q_PROPERTY(bool isActive READ isActive WRITE setIsActive NOTIFY isActiveChanged)

public:
  explicit Reminder(QObject *parent = nullptr);

  QString id() const { return m_id; }
  void setId(const QString &id);

  QString label() const { return m_label; }
  void setLabel(const QString &label);

  int frequency() const { return m_frequency; }
  void setFrequency(int frequency);

  bool isActive() const { return m_isActive; }
  void setIsActive(bool isActive);

  Q_INVOKABLE QVariantMap toMap() const;
  Q_INVOKABLE void regenerateId();

signals:
  void idChanged();
  void labelChanged();
  void frequencyChanged();
  void isActiveChanged();

private:
  static QString newId();

  QString m_id;
  QString m_label;
  int m_frequency = 300000;
  bool m_isActive = true;
};
