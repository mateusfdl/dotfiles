#include "obsidiantodo.hpp"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>
#include <QStringList>
#include <QVariantMap>

#include <algorithm>

ObsidianTodo::ObsidianTodo(QObject *parent) : QObject(parent) {}

QStringList ObsidianTodo::tags() const { return m_tags; }

QVariantList ObsidianTodo::todos() const { return m_todos; }

QStringList ObsidianTodo::taskArguments(const QStringList &arguments) {
  QStringList result;
  result.append(arguments);
  return result;
}

QProcess *ObsidianTodo::startTask(QObject *parent,
                                  const QStringList &arguments) {
  auto *proc = new QProcess(parent);
  proc->setProgram(QString::fromLatin1(TASKWARRIOR_BIN));
  proc->setArguments(taskArguments(arguments));
  proc->start(QProcess::ReadOnly);
  return proc;
}

QByteArray ObsidianTodo::runTask(const QStringList &arguments, bool *ok) {
  QProcess proc;
  proc.setProgram(QString::fromLatin1(TASKWARRIOR_BIN));
  proc.setArguments(taskArguments(arguments));
  proc.start(QProcess::ReadWrite);

  const bool finished = proc.waitForFinished(30000);
  const bool succeeded = finished && proc.exitStatus() == QProcess::NormalExit &&
                         proc.exitCode() == 0;
  if (ok != nullptr)
    *ok = succeeded;

  if (!succeeded)
    return proc.readAllStandardError();

  return proc.readAllStandardOutput();
}

QString ObsidianTodo::normalizeTag(const QString &tag) {
  auto normalized = tag.trimmed();
  while (normalized.startsWith(QLatin1Char('#')) ||
         normalized.startsWith(QLatin1Char('+')))
    normalized.remove(0, 1);

  static const QRegularExpression invalidTagChars(
      QStringLiteral("[^A-Za-z0-9_]") );
  normalized.replace(invalidTagChars, QStringLiteral("_"));
  normalized.replace(QRegularExpression(QStringLiteral("_+")), QStringLiteral("_"));
  return normalized.trimmed();
}

QString ObsidianTodo::markerFromTask(const QVariantMap &task) {
  const auto status = task.value(QStringLiteral("status")).toString();
  if (status == QStringLiteral("completed"))
    return QStringLiteral("x");
  if (status == QStringLiteral("deleted"))
    return QStringLiteral("-");
  if (status == QStringLiteral("waiting"))
    return QStringLiteral(">");

  const auto marker = task.value(QStringLiteral("marker")).toString().trimmed();
  if (!marker.isEmpty())
    return marker.left(1);

  return QStringLiteral(" ");
}

QVariantList ObsidianTodo::parseTodos(const QByteArray &data) {
  const auto doc = QJsonDocument::fromJson(data);
  if (!doc.isArray())
    return {};

  QVariantList result;
  for (const auto &value : doc.array()) {
    const auto task = value.toObject().toVariantMap();
    const auto description = task.value(QStringLiteral("description")).toString();
    const auto uuid = task.value(QStringLiteral("uuid")).toString();
    if (description.isEmpty() || uuid.isEmpty())
      continue;

    QStringList tags;
    const auto rawTags = task.value(QStringLiteral("tags")).toList();
    tags.reserve(rawTags.size());
    for (const auto &rawTag : rawTags) {
      const auto tag = normalizeTag(rawTag.toString());
      if (!tag.isEmpty())
        tags.append(tag);
    }

    QVariantMap entry;
    entry[QStringLiteral("uuid")] = uuid;
    entry[QStringLiteral("noteId")] = uuid;
    entry[QStringLiteral("status")] = markerFromTask(task);
    entry[QStringLiteral("description")] = description;
    entry[QStringLiteral("tags")] = tags;
    result.append(entry);
  }

  return result;
}

QStringList ObsidianTodo::parseTags(const QByteArray &data) {
  const auto doc = QJsonDocument::fromJson(data);
  if (!doc.isArray())
    return {};

  QStringList result;
  for (const auto &value : doc.array()) {
    const auto tags = value.toObject().value(QStringLiteral("tags")).toArray();
    for (const auto &rawTag : tags) {
      const auto tag = normalizeTag(rawTag.toString());
      if (!tag.isEmpty() && !result.contains(tag))
        result.append(tag);
    }
  }

  result.sort(Qt::CaseInsensitive);
  return result;
}

QString ObsidianTodo::uuidForTodo(const QVariantMap &todo) {
  auto uuid = todo.value(QStringLiteral("uuid")).toString();
  if (!uuid.isEmpty())
    return uuid;
  return todo.value(QStringLiteral("noteId")).toString();
}

void ObsidianTodo::fetchTags() {
  auto *proc = startTask(this, {QStringLiteral("export")});

  connect(proc, &QProcess::errorOccurred, this,
          [proc](QProcess::ProcessError) { proc->deleteLater(); });

  connect(proc, &QProcess::finished, this,
          [this, proc](int exitCode, QProcess::ExitStatus exitStatus) {
            proc->deleteLater();
            if (exitStatus != QProcess::NormalExit || exitCode != 0)
              return;

            auto result = parseTags(proc->readAllStandardOutput());
            if (result != m_tags) {
              m_tags = std::move(result);
              emit tagsChanged();
            }
          });
}

void ObsidianTodo::fetchTodos() {
  auto *proc = startTask(this, {QStringLiteral("status:pending"),
                                QStringLiteral("and"),
                                QStringLiteral("due.after:yesterday"),
                                QStringLiteral("and"),
                                QStringLiteral("due.before:tomorrow"),
                                QStringLiteral("export")});

  connect(proc, &QProcess::errorOccurred, this,
          [this, proc](QProcess::ProcessError) {
            proc->deleteLater();
            if (!m_todos.isEmpty()) {
              m_todos.clear();
              emit todosChanged();
            }
          });

  connect(proc, &QProcess::finished, this,
          [this, proc](int exitCode, QProcess::ExitStatus exitStatus) {
            proc->deleteLater();
            if (exitStatus != QProcess::NormalExit || exitCode != 0)
              return;

            auto result = parseTodos(proc->readAllStandardOutput());
            if (result != m_todos) {
              m_todos = std::move(result);
              emit todosChanged();
            }
          });
}

void ObsidianTodo::saveTodo(const QString &description,
                            const QStringList &tags) {
  const auto trimmedDescription = description.trimmed();
  if (trimmedDescription.isEmpty()) {
    emit saveFailed(QStringLiteral("Empty description"));
    return;
  }

  QStringList arguments = {QStringLiteral("add"), trimmedDescription,
                           QStringLiteral("due:today")};
  for (const auto &rawTag : tags) {
    const auto tag = normalizeTag(rawTag);
    if (!tag.isEmpty())
      arguments.append(QStringLiteral("+") + tag);
  }

  auto *proc = startTask(this, arguments);

  connect(proc, &QProcess::errorOccurred, this,
          [this, proc](QProcess::ProcessError) {
            proc->deleteLater();
            emit saveFailed(QStringLiteral("Failed to start Taskwarrior"));
          });

  connect(proc, &QProcess::finished, this,
          [this, proc](int exitCode, QProcess::ExitStatus exitStatus) {
            proc->deleteLater();
            if (exitStatus != QProcess::NormalExit || exitCode != 0) {
              emit saveFailed(QString::fromUtf8(proc->readAllStandardError()));
              return;
            }

            fetchTodos();
            fetchTags();
            emit saved();
          });
}

QString ObsidianTodo::ensureNoteFile(const QString &description,
                                     const QStringList &tags) {
  const auto trimmedDescription = description.trimmed();
  if (trimmedDescription.isEmpty())
    return {};

  bool ok = false;
  const auto data = runTask({QStringLiteral("description:"),
                             trimmedDescription, QStringLiteral("export")},
                            &ok);
  if (ok) {
    const auto todos = parseTodos(data);
    if (!todos.isEmpty())
      return uuidForTodo(todos.first().toMap());
  }

  QStringList arguments = {QStringLiteral("add"), trimmedDescription,
                           QStringLiteral("due:today")};
  for (const auto &rawTag : tags) {
    const auto tag = normalizeTag(rawTag);
    if (!tag.isEmpty())
      arguments.append(QStringLiteral("+") + tag);
  }

  runTask(arguments, &ok);
  if (!ok)
    return {};

  const auto createdData = runTask({QStringLiteral("description:"),
                                    trimmedDescription,
                                    QStringLiteral("export")},
                                   &ok);
  if (!ok)
    return {};

  const auto todos = parseTodos(createdData);
  if (todos.isEmpty())
    return {};

  return uuidForTodo(todos.first().toMap());
}

bool ObsidianTodo::appendSessionLog(const QString &noteId, int focusMinutes,
                                    int breakMinutes,
                                    const QVariantList &events) {
  if (noteId.isEmpty() || events.isEmpty())
    return false;

  QStringList lines;
  lines.append(QStringLiteral("Time: %1 min").arg(focusMinutes));
  lines.append(QStringLiteral("Break time: %1 min").arg(breakMinutes));

  for (const auto &event : events) {
    const auto map = event.toMap();
    const auto time = map.value(QStringLiteral("time")).toString();
    const auto text = map.value(QStringLiteral("text")).toString();
    if (!time.isEmpty() || !text.isEmpty())
      lines.append(QStringLiteral("%1 %2").arg(time, text).trimmed());
  }

  bool ok = false;
  runTask({noteId, QStringLiteral("annotate"), lines.join(QStringLiteral(" | "))},
          &ok);
  return ok;
}

bool ObsidianTodo::setTodoStatus(int index, const QString &marker) {
  if (index < 0 || marker.isEmpty() || index >= m_todos.size())
    return false;

  const auto todo = m_todos.at(index).toMap();
  const auto uuid = uuidForTodo(todo);
  if (uuid.isEmpty())
    return false;

  bool ok = false;
  const auto markerValue = marker.left(1);
  if (markerValue == QStringLiteral("x")) {
    runTask({uuid, QStringLiteral("done")}, &ok);
  } else if (markerValue == QStringLiteral("-")) {
    runTask({uuid, QStringLiteral("delete")}, &ok);
  } else if (markerValue == QStringLiteral(">")) {
    runTask({uuid, QStringLiteral("modify"), QStringLiteral("status:pending"),
             QStringLiteral("due:tomorrow"), QStringLiteral("marker:>")},
            &ok);
  } else {
    runTask({uuid, QStringLiteral("modify"), QStringLiteral("status:pending"),
             QStringLiteral("marker:%1").arg(markerValue)},
            &ok);
  }

  if (ok)
    fetchTodos();

  return ok;
}

bool ObsidianTodo::annotateTodo(int index, const QString &note) {
  const auto trimmedNote = note.trimmed();
  if (index < 0 || trimmedNote.isEmpty() || index >= m_todos.size())
    return false;

  const auto todo = m_todos.at(index).toMap();
  const auto uuid = uuidForTodo(todo);
  if (uuid.isEmpty())
    return false;

  bool ok = false;
  runTask({uuid, QStringLiteral("annotate"), trimmedNote}, &ok);

  if (ok)
    fetchTodos();

  return ok;
}
