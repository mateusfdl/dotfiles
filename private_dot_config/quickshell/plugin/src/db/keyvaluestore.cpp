#include "keyvaluestore.hpp"

#include <QCborParserError>
#include <QCborValue>
#include <QVariantList>

KeyValueStore::KeyValueStore(QObject *parent) : QObject(parent) {}

void KeyValueStore::setDatabase(Sqlite *database) {
  if (database == m_database)
    return;

  m_database = database;
  emit databaseChanged();
}

QVariantMap KeyValueStore::values(const QString &namespaceName) {
  if (m_database == nullptr) {
    emit error(QStringLiteral("values without a database"));
    return {};
  }

  const QVariantList rows = m_database->query(
      QStringLiteral("SELECT key, value FROM key_values WHERE namespace = ?"),
      {namespaceName});

  QVariantMap result;
  for (const QVariant &rawRow : rows) {
    const QVariantMap row = rawRow.toMap();
    const QString key = row.value(QStringLiteral("key")).toString();
    const QByteArray data = row.value(QStringLiteral("value")).toByteArray();

    QCborParserError parserError;
    const QCborValue value = QCborValue::fromCbor(data, &parserError);
    if (parserError.error != QCborError::NoError) {
      emit error(QStringLiteral("Invalid CBOR value for %1/%2")
                     .arg(namespaceName, key));
      continue;
    }

    result.insert(key, value.toVariant());
  }

  return result;
}

bool KeyValueStore::setValue(const QString &namespaceName, const QString &key,
                             const QVariant &value) {
  if (m_database == nullptr) {
    emit error(QStringLiteral("setValue without a database"));
    return false;
  }

  const QByteArray data = QCborValue::fromVariant(value).toCbor();
  return m_database->exec(
      QStringLiteral("INSERT INTO key_values (namespace, key, value) "
                     "VALUES (?, ?, ?) "
                     "ON CONFLICT(namespace, key) DO UPDATE SET "
                     "value = excluded.value"),
      {namespaceName, key, data});
}

bool KeyValueStore::removeValue(const QString &namespaceName,
                                const QString &key) {
  if (m_database == nullptr) {
    emit error(QStringLiteral("removeValue without a database"));
    return false;
  }

  return m_database->exec(
      QStringLiteral("DELETE FROM key_values WHERE namespace = ? AND key = ?"),
      {namespaceName, key});
}
