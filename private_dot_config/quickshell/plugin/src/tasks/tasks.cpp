#include "tasks.hpp"

#include <QDebug>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>
#include <QStringList>
#include <QVariantMap>

Tasks::Tasks(QObject *parent) : QObject(parent) {}

QString Tasks::binPath() const { return m_binPath; }

void Tasks::setBinPath(const QString &binPath) {
  if (binPath.isEmpty() || binPath == m_binPath)
    return;

  m_binPath = binPath;
  emit binPathChanged();
}

QStringList Tasks::tags() const { return m_tags; }

QVariantList Tasks::todos() const { return m_todos; }

QProcess *Tasks::startTask(const QStringList &arguments) {
  auto *proc = new QProcess(this);
  proc->setProgram(m_binPath);
  proc->setArguments(arguments);
  proc->start(QProcess::ReadOnly);
  return proc;
}

QString Tasks::normalizeTag(const QString &tag) {
  auto normalized = tag.trimmed();
  while (normalized.startsWith(QLatin1Char('#')) ||
         normalized.startsWith(QLatin1Char('+')))
    normalized.remove(0, 1);

  static const QRegularExpression invalidTagChars(
      QStringLiteral("[^A-Za-z0-9_]"));
  normalized.replace(invalidTagChars, QStringLiteral("_"));
  normalized.replace(QRegularExpression(QStringLiteral("_+")),
                     QStringLiteral("_"));
  return normalized.trimmed();
}

QString Tasks::markerFromTask(const QVariantMap &task) {
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

QVariantList Tasks::parseTodos(const QByteArray &data) {
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
    entry[QStringLiteral("sourceIndex")] = result.size();
    entry[QStringLiteral("uuid")] = uuid;
    entry[QStringLiteral("status")] = markerFromTask(task);
    entry[QStringLiteral("description")] = description;
    entry[QStringLiteral("tags")] = tags;
    entry[QStringLiteral("annotations")] =
        task.value(QStringLiteral("annotations")).toList();
    result.append(entry);
  }

  return result;
}

QStringList Tasks::parseTags(const QByteArray &data) {
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

QString Tasks::uuidAt(int index) const {
  if (index < 0 || index >= m_todos.size())
    return {};
  return m_todos.at(index).toMap().value(QStringLiteral("uuid")).toString();
}

void Tasks::fetchTags() {
  auto *proc = startTask({QStringLiteral("export")});

  connect(proc, &QProcess::errorOccurred, this, [proc](QProcess::ProcessError) {
    qWarning() << "[Tasks] fetchTags failed:" << proc->errorString();
    proc->deleteLater();
  });

  connect(proc, &QProcess::finished, this,
          [this, proc](int exitCode, QProcess::ExitStatus exitStatus) {
            proc->deleteLater();
            if (exitStatus != QProcess::NormalExit || exitCode != 0) {
              qWarning() << "[Tasks] fetchTags exited" << exitCode
                         << proc->readAllStandardError();
              return;
            }

            auto result = parseTags(proc->readAllStandardOutput());
            if (result != m_tags) {
              m_tags = std::move(result);
              emit tagsChanged();
            }
          });
}

void Tasks::fetchTodos() {
  auto *proc = startTask(
      {QStringLiteral("status:pending"), QStringLiteral("export")});

  connect(proc, &QProcess::errorOccurred, this,
          [this, proc](QProcess::ProcessError) {
            qWarning() << "[Tasks] fetchTodos failed:" << proc->errorString();
            proc->deleteLater();
            if (!m_todos.isEmpty()) {
              m_todos.clear();
              emit todosChanged();
            }
          });

  connect(proc, &QProcess::finished, this,
          [this, proc](int exitCode, QProcess::ExitStatus exitStatus) {
            proc->deleteLater();
            if (exitStatus != QProcess::NormalExit || exitCode != 0) {
              qWarning() << "[Tasks] fetchTodos exited" << exitCode
                         << proc->readAllStandardError();
              return;
            }

            auto result = parseTodos(proc->readAllStandardOutput());
            if (result != m_todos) {
              m_todos = std::move(result);
              emit todosChanged();
            }
          });
}

void Tasks::saveTodo(const QString &description, const QStringList &tags) {
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

  auto *proc = startTask(arguments);

  connect(proc, &QProcess::errorOccurred, this,
          [this, proc](QProcess::ProcessError procError) {
            if (procError != QProcess::FailedToStart)
              return;
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

void Tasks::runMutation(const QStringList &arguments, const QString &label) {
  auto *proc = startTask(arguments);

  connect(proc, &QProcess::errorOccurred, this,
          [proc, label](QProcess::ProcessError procError) {
            if (procError != QProcess::FailedToStart)
              return;
            qWarning() << "[Tasks]" << label
                       << "failed to start:" << proc->errorString();
            proc->deleteLater();
          });

  connect(proc, &QProcess::finished, this,
          [this, proc, label](int exitCode, QProcess::ExitStatus exitStatus) {
            proc->deleteLater();
            if (exitStatus != QProcess::NormalExit || exitCode != 0) {
              qWarning() << "[Tasks]" << label << "exited" << exitCode
                         << proc->readAllStandardError();
              return;
            }

            fetchTodos();
          });
}

void Tasks::appendSessionLog(const QString &uuid, int focusMinutes,
                             int breakMinutes, const QVariantList &events) {
  if (uuid.isEmpty() || events.isEmpty())
    return;

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

  runMutation({uuid, QStringLiteral("annotate"),
               lines.join(QStringLiteral(" | "))},
              QStringLiteral("appendSessionLog"));
}

void Tasks::setTodoStatus(int index, const QString &marker) {
  const auto uuid = uuidAt(index);
  if (uuid.isEmpty() || marker.isEmpty())
    return;

  const auto markerValue = marker.left(1);
  if (markerValue == QStringLiteral("x")) {
    runMutation({uuid, QStringLiteral("done")}, QStringLiteral("setTodoStatus"));
  } else if (markerValue == QStringLiteral("-")) {
    runMutation({uuid, QStringLiteral("delete")},
                QStringLiteral("setTodoStatus"));
  } else if (markerValue == QStringLiteral(">")) {
    runMutation({uuid, QStringLiteral("modify"), QStringLiteral("status:pending"),
                 QStringLiteral("due:tomorrow"), QStringLiteral("marker:>")},
                QStringLiteral("setTodoStatus"));
  } else {
    runMutation({uuid, QStringLiteral("modify"), QStringLiteral("status:pending"),
                 QStringLiteral("marker:%1").arg(markerValue)},
                QStringLiteral("setTodoStatus"));
  }
}

void Tasks::annotateTodo(int index, const QString &note) {
  const auto trimmedNote = note.trimmed();
  const auto uuid = uuidAt(index);
  if (uuid.isEmpty() || trimmedNote.isEmpty())
    return;

  runMutation({uuid, QStringLiteral("annotate"), trimmedNote},
              QStringLiteral("annotateTodo"));
}
