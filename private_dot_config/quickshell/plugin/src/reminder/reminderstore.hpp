#pragma once

#include "sqlite.hpp"

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>

class ReminderStore : public QObject {
  Q_OBJECT
  QML_ELEMENT
  Q_PROPERTY(Sqlite *database READ database WRITE setDatabase NOTIFY databaseChanged)

public:
  explicit ReminderStore(QObject *parent = nullptr);

  Sqlite *database() const { return m_database; }
  void setDatabase(Sqlite *database);

  Q_INVOKABLE QVariantMap createReminder(const QString &label, int frequency,
                                         bool isActive = true);
  Q_INVOKABLE QVariantMap toggleReminder(const QString &id);
  Q_INVOKABLE bool deleteReminder(const QString &id);
  Q_INVOKABLE QVariantList remindersByIsActive(bool isActive);

signals:
  void databaseChanged();
  void error(const QString &message);

private:
  QVariantList query(const QString &sql, const QVariantList &bindings);
  bool exec(const QString &sql, const QVariantList &bindings);
  QVariantMap reminderById(const QString &id);
  static QString newId();
  static QVariantMap normalizeReminder(const QVariantMap &row);
  static QVariantMap reminderMap(const QString &id, const QString &label,
                                 int frequency, bool isActive);

  Sqlite *m_database = nullptr;
};
