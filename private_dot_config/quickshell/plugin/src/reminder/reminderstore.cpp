#include "reminderstore.hpp"

#include <QUuid>

ReminderStore::ReminderStore(QObject *parent) : QObject(parent) {}

void ReminderStore::setDatabase(Sqlite *database) {
  if (database == m_database)
    return;

  m_database = database;
  emit databaseChanged();
}

QString ReminderStore::newId() {
  return QUuid::createUuid().toString(QUuid::WithoutBraces);
}

QVariantMap ReminderStore::reminderMap(const QString &id, const QString &label,
                                       int frequency, bool isActive) {
  return {
      {QStringLiteral("id"), id},
      {QStringLiteral("label"), label},
      {QStringLiteral("frequency"), frequency},
      {QStringLiteral("isActive"), isActive},
  };
}

QVariantMap ReminderStore::normalizeReminder(const QVariantMap &row) {
  return reminderMap(row.value(QStringLiteral("id")).toString(),
                     row.value(QStringLiteral("label")).toString(),
                     row.value(QStringLiteral("frequency")).toInt(),
                     row.value(QStringLiteral("isActive")).toBool());
}

QVariantList ReminderStore::query(const QString &sql,
                                  const QVariantList &bindings) {
  if (m_database == nullptr) {
    emit error(QStringLiteral("query without a database"));
    return {};
  }

  return m_database->query(sql, bindings);
}

bool ReminderStore::exec(const QString &sql, const QVariantList &bindings) {
  if (m_database == nullptr) {
    emit error(QStringLiteral("exec without a database"));
    return false;
  }

  return m_database->exec(sql, bindings);
}

QVariantMap ReminderStore::createReminder(const QString &label, int frequency,
                                          bool isActive) {
  const QString id = newId();
  const int active = isActive ? 1 : 0;
  if (!exec(QStringLiteral("INSERT INTO reminders (id, label, frequency, "
                           "isActive) VALUES (?, ?, ?, ?)"),
            {id, label, frequency, active}))
    return {};

  return reminderMap(id, label, frequency, isActive);
}

QVariantMap ReminderStore::toggleReminder(const QString &id) {
  const QVariantMap current = reminderById(id);
  if (current.isEmpty())
    return {};

  const bool isActive = current.value(QStringLiteral("isActive")).toBool();
  const bool nextActive = !isActive;
  if (!exec(QStringLiteral("UPDATE reminders SET isActive = ? WHERE id = ?"),
            {nextActive ? 1 : 0, id}))
    return {};

  return reminderById(id);
}

bool ReminderStore::deleteReminder(const QString &id) {
  return exec(QStringLiteral("DELETE FROM reminders WHERE id = ?"), {id});
}

QVariantList ReminderStore::remindersByIsActive(bool isActive) {
  const QVariantList rows =
      query(QStringLiteral("SELECT id, label, frequency, isActive FROM "
                           "reminders WHERE isActive = ? ORDER BY label"),
            {isActive ? 1 : 0});

  QVariantList reminders;
  for (const QVariant &row : rows)
    reminders.append(normalizeReminder(row.toMap()));

  return reminders;
}

QVariantMap ReminderStore::reminderById(const QString &id) {
  const QVariantList rows =
      query(QStringLiteral("SELECT id, label, frequency, isActive FROM "
                           "reminders WHERE id = ? LIMIT 1"),
            {id});
  if (rows.isEmpty()) {
    emit error(QStringLiteral("Reminder not found: %1").arg(id));
    return {};
  }

  return normalizeReminder(rows.first().toMap());
}
