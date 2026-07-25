#include "reminder.hpp"

#include <QUuid>

Reminder::Reminder(QObject *parent) : QObject(parent), m_id(newId()) {}

QString Reminder::newId() {
  return QUuid::createUuid().toString(QUuid::WithoutBraces);
}

void Reminder::setId(const QString &id) {
  if (id == m_id)
    return;

  m_id = id;
  emit idChanged();
}

void Reminder::setLabel(const QString &label) {
  if (label == m_label)
    return;

  m_label = label;
  emit labelChanged();
}

void Reminder::setFrequency(int frequency) {
  if (frequency == m_frequency)
    return;

  m_frequency = frequency;
  emit frequencyChanged();
}

void Reminder::setIsActive(bool isActive) {
  if (isActive == m_isActive)
    return;

  m_isActive = isActive;
  emit isActiveChanged();
}

QVariantMap Reminder::toMap() const {
  return {
      {QStringLiteral("id"), m_id},
      {QStringLiteral("label"), m_label},
      {QStringLiteral("frequency"), m_frequency},
      {QStringLiteral("isActive"), m_isActive},
  };
}

void Reminder::regenerateId() { setId(newId()); }
