#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariantList>
#include <QtQml/qqmlregistration.h>

class Sqlite : public QObject {
  Q_OBJECT
  QML_ELEMENT
  Q_PROPERTY(QString path READ path WRITE setPath NOTIFY pathChanged)
  Q_PROPERTY(bool open READ isOpen NOTIFY openChanged)

public:
  explicit Sqlite(QObject *parent = nullptr);
  ~Sqlite() override;

  QString path() const { return m_path; }
  void setPath(const QString &path);
  bool isOpen() const { return m_open; }

  Q_INVOKABLE QVariantList query(const QString &sql,
                                 const QVariantList &bindings = {});
  Q_INVOKABLE bool exec(const QString &sql,
                        const QVariantList &bindings = {});
  Q_INVOKABLE bool migrate(const QString &migrationsDir);

signals:
  void pathChanged();
  void openChanged();
  void error(const QString &message);

private:
  static QString expandPath(const QString &path);
  static QStringList splitStatements(const QString &sql);
  void openDatabase();
  void closeDatabase();
  void setOpen(bool open);
  bool ensureMigrationsTable();
  int appliedVersion(const QString &namespaceName);
  bool applyMigrationFile(const QString &namespaceName, int version,
                          const QString &filePath);

  const QString m_connectionName;
  QString m_path;
  bool m_open = false;
};
