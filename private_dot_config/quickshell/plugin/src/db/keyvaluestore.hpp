#pragma once

#include "sqlite.hpp"

#include <QObject>
#include <QString>
#include <QVariant>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>

class KeyValueStore : public QObject {
  Q_OBJECT
  QML_ELEMENT
  Q_PROPERTY(Sqlite *database READ database WRITE setDatabase NOTIFY databaseChanged)

public:
  explicit KeyValueStore(QObject *parent = nullptr);

  Sqlite *database() const { return m_database; }
  void setDatabase(Sqlite *database);

  Q_INVOKABLE QVariantMap values(const QString &namespaceName);
  Q_INVOKABLE bool setValue(const QString &namespaceName, const QString &key,
                            const QVariant &value);
  Q_INVOKABLE bool removeValue(const QString &namespaceName,
                               const QString &key);

signals:
  void databaseChanged();
  void error(const QString &message);

private:
  Sqlite *m_database = nullptr;
};
