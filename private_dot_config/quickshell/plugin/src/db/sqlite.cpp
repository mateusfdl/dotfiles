#include "sqlite.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QList>
#include <QPair>
#include <QRegularExpression>
#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>
#include <QSqlRecord>
#include <QStandardPaths>

#include <algorithm>

Sqlite::Sqlite(QObject *parent)
    : QObject(parent),
      m_connectionName(QStringLiteral("qsutils_sqlite_%1")
                           .arg(reinterpret_cast<quintptr>(this))) {}

Sqlite::~Sqlite() { closeDatabase(); }

QString Sqlite::expandPath(const QString &path) {
  if (path == QStringLiteral("~"))
    return QStandardPaths::writableLocation(QStandardPaths::HomeLocation);
  if (path.startsWith(QStringLiteral("~/")))
    return QStandardPaths::writableLocation(QStandardPaths::HomeLocation) +
           path.mid(1);
  return path;
}

void Sqlite::setPath(const QString &path) {
  const QString expanded = expandPath(path);
  if (expanded == m_path)
    return;

  m_path = expanded;
  emit pathChanged();
  openDatabase();
}

void Sqlite::setOpen(bool open) {
  if (open == m_open)
    return;
  m_open = open;
  emit openChanged();
}

void Sqlite::closeDatabase() {
  if (QSqlDatabase::contains(m_connectionName)) {
    {
      QSqlDatabase db = QSqlDatabase::database(m_connectionName, false);
      if (db.isOpen())
        db.close();
    }
    QSqlDatabase::removeDatabase(m_connectionName);
  }
  setOpen(false);
}

void Sqlite::openDatabase() {
  closeDatabase();

  if (m_path.isEmpty())
    return;

  const QString directory = QFileInfo(m_path).absolutePath();
  if (!QDir().mkpath(directory)) {
    emit error(QStringLiteral("Failed to create directory: %1").arg(directory));
    return;
  }

  QSqlDatabase db =
      QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), m_connectionName);
  db.setDatabaseName(m_path);
  if (!db.open()) {
    emit error(QStringLiteral("Failed to open database %1: %2")
                   .arg(m_path, db.lastError().text()));
    QSqlDatabase::removeDatabase(m_connectionName);
    return;
  }

  setOpen(true);
}

QVariantList Sqlite::query(const QString &sql, const QVariantList &bindings) {
  if (!m_open) {
    emit error(QStringLiteral("query on a closed database"));
    return {};
  }

  QSqlQuery statement(QSqlDatabase::database(m_connectionName));
  if (!statement.prepare(sql)) {
    emit error(QStringLiteral("Failed to prepare query: %1")
                   .arg(statement.lastError().text()));
    return {};
  }
  for (const QVariant &binding : bindings)
    statement.addBindValue(binding);

  if (!statement.exec()) {
    emit error(
        QStringLiteral("Query failed: %1").arg(statement.lastError().text()));
    return {};
  }

  QVariantList rows;
  const QSqlRecord record = statement.record();
  const int columnCount = record.count();
  while (statement.next()) {
    QVariantMap row;
    for (int column = 0; column < columnCount; ++column)
      row.insert(record.fieldName(column), statement.value(column));
    rows.append(row);
  }
  return rows;
}

bool Sqlite::exec(const QString &sql, const QVariantList &bindings) {
  if (!m_open) {
    emit error(QStringLiteral("exec on a closed database"));
    return false;
  }

  QSqlQuery statement(QSqlDatabase::database(m_connectionName));
  if (!statement.prepare(sql)) {
    emit error(QStringLiteral("Failed to prepare statement: %1")
                   .arg(statement.lastError().text()));
    return false;
  }
  for (const QVariant &binding : bindings)
    statement.addBindValue(binding);

  if (!statement.exec()) {
    emit error(QStringLiteral("Statement failed: %1")
                   .arg(statement.lastError().text()));
    return false;
  }

  return true;
}

QStringList Sqlite::splitStatements(const QString &sql) {
  QStringList statements;
  QString current;
  QChar quote;
  bool inQuote = false;
  bool inLineComment = false;
  bool inBlockComment = false;

  for (int i = 0; i < sql.size(); ++i) {
    const QChar c = sql.at(i);
    const QChar next = i + 1 < sql.size() ? sql.at(i + 1) : QChar();

    if (inLineComment) {
      current.append(c);
      if (c == QLatin1Char('\n'))
        inLineComment = false;
      continue;
    }

    if (inBlockComment) {
      current.append(c);
      if (c == QLatin1Char('*') && next == QLatin1Char('/')) {
        current.append(next);
        ++i;
        inBlockComment = false;
      }
      continue;
    }

    if (inQuote) {
      current.append(c);
      if (c == quote && next == quote) {
        current.append(next);
        ++i;
        continue;
      }
      if (c == quote)
        inQuote = false;
      continue;
    }

    if (c == QLatin1Char('-') && next == QLatin1Char('-')) {
      inLineComment = true;
      current.append(c);
      current.append(next);
      ++i;
      continue;
    }

    if (c == QLatin1Char('/') && next == QLatin1Char('*')) {
      inBlockComment = true;
      current.append(c);
      current.append(next);
      ++i;
      continue;
    }

    if (c == QLatin1Char('\'') || c == QLatin1Char('"')) {
      inQuote = true;
      quote = c;
      current.append(c);
      continue;
    }

    if (c == QLatin1Char(';')) {
      const QString trimmed = current.trimmed();
      if (!trimmed.isEmpty())
        statements.append(trimmed);
      current.clear();
      continue;
    }

    current.append(c);
  }

  const QString trailing = current.trimmed();
  if (!trailing.isEmpty())
    statements.append(trailing);

  return statements;
}

bool Sqlite::ensureMigrationsTable() {
  return exec(QStringLiteral(
      "CREATE TABLE IF NOT EXISTS schema_migrations ("
      "namespace TEXT NOT NULL, version INTEGER NOT NULL, "
      "PRIMARY KEY (namespace, version))"));
}

int Sqlite::appliedVersion(const QString &namespaceName) {
  const QVariantList rows =
      query(QStringLiteral(
                "SELECT MAX(version) AS version FROM schema_migrations "
                "WHERE namespace = ?"),
            {namespaceName});
  if (rows.isEmpty())
    return 0;
  return rows.first().toMap().value(QStringLiteral("version")).toInt();
}

bool Sqlite::applyMigrationFile(const QString &namespaceName, int version,
                                const QString &filePath) {
  QFile file(filePath);
  if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
    emit error(QStringLiteral("Failed to read migration %1").arg(filePath));
    return false;
  }
  const QString contents = QString::fromUtf8(file.readAll());
  file.close();

  QSqlDatabase db = QSqlDatabase::database(m_connectionName);
  if (!db.transaction()) {
    emit error(QStringLiteral("Failed to begin transaction for %1: %2")
                   .arg(filePath, db.lastError().text()));
    return false;
  }

  const QStringList statements = splitStatements(contents);
  for (const QString &statement : statements) {
    if (!exec(statement)) {
      db.rollback();
      return false;
    }
  }

  if (!exec(QStringLiteral("INSERT INTO schema_migrations (namespace, version) "
                           "VALUES (?, ?)"),
            {namespaceName, version})) {
    db.rollback();
    return false;
  }

  if (!db.commit()) {
    emit error(QStringLiteral("Failed to commit migration %1: %2")
                   .arg(filePath, db.lastError().text()));
    db.rollback();
    return false;
  }

  return true;
}

bool Sqlite::migrate(const QString &migrationsDir) {
  if (!m_open) {
    emit error(QStringLiteral("migrate on a closed database"));
    return false;
  }

  const QDir root(expandPath(migrationsDir));
  if (!root.exists())
    return true;

  if (!ensureMigrationsTable())
    return false;

  static const QRegularExpression versionPrefix(QStringLiteral("^(\\d+)"));

  const QStringList namespaces =
      root.entryList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name);
  for (const QString &namespaceName : namespaces) {
    QDir namespaceDir(root.filePath(namespaceName));
    const QFileInfoList files = namespaceDir.entryInfoList(
        {QStringLiteral("*.sql")}, QDir::Files, QDir::Name);

    QList<QPair<int, QString>> pending;
    const int applied = appliedVersion(namespaceName);
    for (const QFileInfo &file : files) {
      const auto match = versionPrefix.match(file.fileName());
      if (!match.hasMatch()) {
        emit error(QStringLiteral("Migration %1 has no numeric version prefix")
                       .arg(file.filePath()));
        return false;
      }
      const int version = match.captured(1).toInt();
      if (version > applied)
        pending.append({version, file.filePath()});
    }

    std::sort(pending.begin(), pending.end(),
              [](const auto &a, const auto &b) { return a.first < b.first; });

    for (const auto &[version, filePath] : pending) {
      if (!applyMigrationFile(namespaceName, version, filePath))
        return false;
    }
  }

  return true;
}
