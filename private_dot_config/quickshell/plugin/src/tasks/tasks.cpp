#include "tasks.hpp"

#include <QDate>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QPointer>
#include <QProcess>
#include <QTime>
#include <QTimer>
#include <QTimeZone>
#include <QVariantMap>

#include <utility>

namespace {
constexpr auto VIKUNJA_BIN = "/run/current-system/sw/bin/vikunja-cli";
constexpr auto VIKUNJA_SCRIPT =
    "set -a; . \"$HOME/.tokens\"; exec "
    "/run/current-system/sw/bin/vikunja-cli \"$@\"";
}

Tasks::Tasks(QObject *parent) : QObject(parent) {}

QStringList Tasks::tags() const { return m_tags; }

QVariantList Tasks::todos() const { return m_todos; }

qint64 Tasks::projectId() const { return m_projectId; }

void Tasks::setProjectId(qint64 projectId) {
  if (projectId <= 0 || projectId == m_projectId)
    return;

  m_projectId = projectId;
  emit projectIdChanged();
}

void Tasks::runCli(const QStringList &arguments, CliCallback callback) {
  auto *process = new QProcess(this);
  process->setProgram(QStringLiteral("/bin/sh"));

  QStringList shellArguments = {QStringLiteral("-c"),
                                QString::fromLatin1(VIKUNJA_SCRIPT),
                                QString::fromLatin1(VIKUNJA_BIN)};
  shellArguments.append(arguments);
  process->setArguments(shellArguments);

  connect(process, &QProcess::errorOccurred, this,
          [process, callback](QProcess::ProcessError error) {
            if (error != QProcess::FailedToStart ||
                process->property("completed").toBool())
              return;

            process->setProperty("completed", true);
            callback(false, {}, QStringLiteral("Failed to start vikunja-cli"));
            process->deleteLater();
          });

  connect(process, &QProcess::finished, this,
          [process, callback](int exitCode, QProcess::ExitStatus exitStatus) {
            if (process->property("completed").toBool())
              return;

            process->setProperty("completed", true);
            const auto output = process->readAllStandardOutput();
            const auto errorOutput = process->readAllStandardError();
            const auto succeeded = exitStatus == QProcess::NormalExit &&
                                   exitCode == 0 &&
                                   !process->property("timedOut").toBool();
            callback(succeeded, output,
                     succeeded
                         ? QString{}
                         : errorMessage(
                               errorOutput,
                               process->property("timedOut").toBool()
                                   ? QStringLiteral("vikunja-cli timed out")
                                   : QStringLiteral("vikunja-cli failed")));
            process->deleteLater();
          });

  process->start(QProcess::ReadOnly);
  QPointer<QProcess> guardedProcess(process);
  QTimer::singleShot(CLI_TIMEOUT_MS, this, [guardedProcess] {
    if (guardedProcess.isNull() ||
        guardedProcess->property("completed").toBool())
      return;

    guardedProcess->setProperty("timedOut", true);
    guardedProcess->kill();
  });
}

Tasks::ItemPage Tasks::parseTodoPage(const QByteArray &data) {
  const auto document = QJsonDocument::fromJson(data);
  if (!document.isObject())
    return {};

  const auto root = document.object();
  const auto dataValue = root.value(QStringLiteral("data"));
  if (!dataValue.isArray())
    return {};

  ItemPage page;
  page.valid = true;
  page.page = root.value(QStringLiteral("page")).toInt();
  page.totalPages = root.value(QStringLiteral("total_pages")).toInt();

  for (const auto &value : dataValue.toArray()) {
    if (!value.isObject())
      continue;

    const auto task = value.toObject().toVariantMap();
    const auto id = task.value(QStringLiteral("id")).toLongLong();
    const auto title = task.value(QStringLiteral("title")).toString().trimmed();
    if (id <= 0 || title.isEmpty())
      continue;

    QStringList labels;
    for (const auto &rawLabel : task.value(QStringLiteral("labels")).toList()) {
      const auto label =
          rawLabel.toMap().value(QStringLiteral("title")).toString().trimmed();
      if (!label.isEmpty() && !labels.contains(label))
        labels.append(label);
    }

    QVariantMap todo;
    const auto taskId = QString::number(id);
    todo[QStringLiteral("uuid")] = taskId;
    todo[QStringLiteral("noteId")] = taskId;
    todo[QStringLiteral("status")] = markerFromTask(task);
    todo[QStringLiteral("description")] = title;
    todo[QStringLiteral("tags")] = labels;
    todo[QStringLiteral("annotations")] = QVariantList{};
    page.items.append(todo);
  }

  return page;
}

Tasks::LabelPage Tasks::parseLabelPage(const QByteArray &data) {
  const auto document = QJsonDocument::fromJson(data);
  if (!document.isObject())
    return {};

  const auto root = document.object();
  const auto dataValue = root.value(QStringLiteral("data"));
  if (!dataValue.isArray())
    return {};

  LabelPage page;
  page.valid = true;
  page.page = root.value(QStringLiteral("page")).toInt();
  page.totalPages = root.value(QStringLiteral("total_pages")).toInt();

  for (const auto &value : dataValue.toArray()) {
    const auto label = value.toObject();
    const auto id = label.value(QStringLiteral("id")).toInteger();
    const auto title = label.value(QStringLiteral("title")).toString().trimmed();
    if (id > 0 && !title.isEmpty())
      page.labels.insert(title, id);
  }

  return page;
}

Tasks::ItemPage Tasks::parseCommentPage(const QByteArray &data) {
  const auto document = QJsonDocument::fromJson(data);
  if (!document.isObject())
    return {};

  const auto root = document.object();
  const auto dataValue = root.value(QStringLiteral("data"));
  if (!dataValue.isArray())
    return {};

  ItemPage page;
  page.valid = true;
  page.page = root.value(QStringLiteral("page")).toInt();
  page.totalPages = root.value(QStringLiteral("total_pages")).toInt();

  for (const auto &value : dataValue.toArray()) {
    const auto comment = value.toObject();
    const auto description =
        comment.value(QStringLiteral("comment")).toString().trimmed();
    if (description.isEmpty())
      continue;

    page.items.append(QVariantMap{
        {QStringLiteral("description"), description},
        {QStringLiteral("entry"),
         comment.value(QStringLiteral("created")).toString()}});
  }

  return page;
}

QString Tasks::markerFromTask(const QVariantMap &task, const QDateTime &now) {
  if (task.value(QStringLiteral("done")).toBool())
    return QStringLiteral("x");

  const auto progress = task.value(QStringLiteral("percent_done")).toDouble();
  if (progress > 0.0 && progress < 1.0)
    return QStringLiteral("/");

  const auto priority = task.value(QStringLiteral("priority")).toInt();
  if (priority == 1)
    return QStringLiteral("?");
  if (priority > 1)
    return QStringLiteral("!");

  const auto dueDate = QDateTime::fromString(
      task.value(QStringLiteral("due_date")).toString(), Qt::ISODate);
  if (dueDate.isValid() &&
      dueDate.toLocalTime().date() > now.toLocalTime().date())
    return QStringLiteral(">");

  return QStringLiteral(" ");
}

QString Tasks::cleanLabel(const QString &label) {
  auto cleaned = label.trimmed();
  while (cleaned.startsWith(QLatin1Char('#')) ||
         cleaned.startsWith(QLatin1Char('+')))
    cleaned.remove(0, 1);
  return cleaned.trimmed();
}

QString Tasks::taskIdAt(const QVariantList &todos, int index) {
  if (index < 0 || index >= todos.size())
    return {};
  return todos.at(index).toMap().value(QStringLiteral("uuid")).toString();
}

QString Tasks::dueDateFor(const QDate &date) {
  const QDateTime endOfDay(date, QTime(23, 59, 59));
  if (!endOfDay.isValid())
    return QDateTime(date, QTime(23, 59, 59), QTimeZone::UTC)
        .toString(Qt::ISODate);

  return endOfDay.toOffsetFromUtc(endOfDay.offsetFromUtc())
      .toString(Qt::ISODate);
}

QString Tasks::errorMessage(const QByteArray &stderrData,
                            const QString &fallback) {
  const auto document = QJsonDocument::fromJson(stderrData);
  if (document.isObject()) {
    const auto error =
        document.object().value(QStringLiteral("error")).toString().trimmed();
    if (!error.isEmpty())
      return error;
  }

  const auto error = QString::fromUtf8(stderrData).trimmed();
  return error.isEmpty() ? fallback : error;
}

void Tasks::fetchTodos() {
  const auto generation = ++m_todoGeneration;
  m_pendingCommentIds.clear();
  m_activeCommentFetches = 0;
  fetchTodoPage(1, {}, generation);
}

void Tasks::fetchTodoPage(int page, QVariantList accumulated,
                          quint64 generation) {
  runCli({QStringLiteral("tasks"), QStringLiteral("list"),
          QStringLiteral("--filter"), QStringLiteral("done = false"),
          QStringLiteral("--sort"), QStringLiteral("due_date"),
          QStringLiteral("--order-by"), QStringLiteral("asc"),
          QStringLiteral("--page"), QString::number(page),
          QStringLiteral("--per-page"), QStringLiteral("50")},
         [this, page, accumulated = std::move(accumulated), generation](
             bool succeeded, const QByteArray &output,
             const QString &error) mutable {
           if (generation != m_todoGeneration)
             return;
           if (!succeeded) {
             emit operationFailed(error);
             return;
           }

           const auto result = parseTodoPage(output);
           if (!result.valid) {
             emit operationFailed(QStringLiteral("Invalid Vikunja task data"));
             return;
           }

           accumulated.append(result.items);
           if (result.totalPages > page) {
             fetchTodoPage(page + 1, std::move(accumulated), generation);
             return;
           }

           for (qsizetype index = 0; index < accumulated.size(); ++index) {
             auto todo = accumulated.at(index).toMap();
             todo[QStringLiteral("sourceIndex")] = index;
             accumulated[index] = todo;
           }

           if (accumulated != m_todos) {
             m_todos = std::move(accumulated);
             emit todosChanged();
           }

           m_pendingCommentIds.reserve(m_todos.size());
           for (const auto &todo : std::as_const(m_todos))
             m_pendingCommentIds.append(
                 todo.toMap().value(QStringLiteral("uuid")).toString());
           startCommentFetches(generation);
         });
}

void Tasks::fetchTags() {
  fetchLabelPage(1, {}, [this](bool succeeded,
                              const QHash<QString, qint64> &labels,
                              const QString &error) {
    if (!succeeded) {
      emit operationFailed(error);
      return;
    }

    m_labelIds = labels;
    auto titles = labels.keys();
    titles.sort(Qt::CaseInsensitive);
    if (titles != m_tags) {
      m_tags = std::move(titles);
      emit tagsChanged();
    }
  });
}

void Tasks::fetchLabelPage(int page, QHash<QString, qint64> accumulated,
                           LabelsCallback callback) {
  runCli({QStringLiteral("labels"), QStringLiteral("list"),
          QStringLiteral("--page"), QString::number(page),
          QStringLiteral("--per-page"), QStringLiteral("50")},
         [this, page, accumulated = std::move(accumulated),
          callback = std::move(callback)](bool succeeded,
                                          const QByteArray &output,
                                          const QString &error) mutable {
           if (!succeeded) {
             callback(false, {}, error);
             return;
           }

           const auto result = parseLabelPage(output);
           if (!result.valid) {
             callback(false, {}, QStringLiteral("Invalid Vikunja label data"));
             return;
           }

           accumulated.insert(result.labels);
           if (result.totalPages > page) {
             fetchLabelPage(page + 1, std::move(accumulated),
                            std::move(callback));
             return;
           }

           callback(true, accumulated, {});
         });
}

void Tasks::startCommentFetches(quint64 generation) {
  while (generation == m_todoGeneration &&
         m_activeCommentFetches < COMMENT_CONCURRENCY &&
         !m_pendingCommentIds.isEmpty()) {
    const auto taskId = m_pendingCommentIds.takeFirst();
    ++m_activeCommentFetches;
    fetchCommentPage(taskId, 1, {}, generation);
  }
}

void Tasks::fetchCommentPage(const QString &taskId, int page,
                             QVariantList accumulated, quint64 generation) {
  runCli({QStringLiteral("tasks"), QStringLiteral("comments"),
          QStringLiteral("list"), QStringLiteral("--task-id"), taskId,
          QStringLiteral("--page"), QString::number(page),
          QStringLiteral("--per-page"), QStringLiteral("50")},
         [this, taskId, page, accumulated = std::move(accumulated),
          generation](bool succeeded, const QByteArray &output,
                      const QString &) mutable {
           if (generation != m_todoGeneration)
             return;

           if (!succeeded) {
             completeCommentFetch(generation);
             return;
           }

           const auto result = parseCommentPage(output);
           if (!result.valid) {
             completeCommentFetch(generation);
             return;
           }

           accumulated.append(result.items);
           if (result.totalPages > page) {
             fetchCommentPage(taskId, page + 1, std::move(accumulated),
                              generation);
             return;
           }

           for (qsizetype index = 0; index < m_todos.size(); ++index) {
             auto todo = m_todos.at(index).toMap();
             if (todo.value(QStringLiteral("uuid")).toString() != taskId)
               continue;

             if (todo.value(QStringLiteral("annotations")).toList() !=
                 accumulated) {
               todo[QStringLiteral("annotations")] = accumulated;
               m_todos[index] = todo;
               emit todosChanged();
             }
             break;
           }

           completeCommentFetch(generation);
         });
}

void Tasks::completeCommentFetch(quint64 generation) {
  if (generation != m_todoGeneration)
    return;

  --m_activeCommentFetches;
  startCommentFetches(generation);
}

void Tasks::saveTodo(const QString &description, const QStringList &tags) {
  const auto title = description.trimmed();
  if (title.isEmpty()) {
    emit saveFailed(QStringLiteral("Empty description"));
    return;
  }
  if (m_projectId <= 0) {
    emit saveFailed(QStringLiteral("Invalid Vikunja project ID"));
    return;
  }

  QStringList cleanedTags;
  for (const auto &rawTag : tags) {
    const auto tag = cleanLabel(rawTag);
    if (!tag.isEmpty() && !cleanedTags.contains(tag))
      cleanedTags.append(tag);
  }

  runCli({QStringLiteral("tasks"), QStringLiteral("create"),
          QStringLiteral("--project-id"), QString::number(m_projectId),
          QStringLiteral("--title"), title, QStringLiteral("--due-date"),
          dueDateFor(QDate::currentDate())},
         [this, cleanedTags = std::move(cleanedTags)](
             bool succeeded, const QByteArray &output, const QString &error) {
           if (!succeeded) {
             emit saveFailed(error);
             return;
           }

           const auto document = QJsonDocument::fromJson(output);
           const auto taskId =
               document.object().value(QStringLiteral("id")).toInteger();
           if (!document.isObject() || taskId <= 0) {
             emit saveFailed(QStringLiteral("Invalid created Vikunja task"));
             return;
           }

           auto operation = std::make_shared<SaveOperation>();
           operation->taskId = QString::number(taskId);
           operation->tags = cleanedTags;
           fetchLabelPage(
               1, {},
               [this, operation](bool labelsSucceeded,
                                 const QHash<QString, qint64> &labels,
                                 const QString &labelsError) {
                 if (!labelsSucceeded) {
                   emit saveFailed(labelsError);
                   refreshAfterMutation();
                   return;
                 }

                 operation->labels = labels;
                 continueSave(operation);
               });
         });
}

void Tasks::continueSave(const std::shared_ptr<SaveOperation> &operation) {
  if (operation->index >= operation->tags.size()) {
    refreshAfterMutation();
    emit saved();
    return;
  }

  const auto tag = operation->tags.at(operation->index);
  const auto existingLabel = operation->labels.constFind(tag);
  if (existingLabel != operation->labels.cend()) {
    attachSaveLabel(operation, existingLabel.value());
    return;
  }

  runCli({QStringLiteral("labels"), QStringLiteral("create"),
          QStringLiteral("--title"), tag},
         [this, operation, tag](bool succeeded, const QByteArray &output,
                                const QString &error) {
           if (!succeeded) {
             emit saveFailed(error);
             refreshAfterMutation();
             return;
           }

           const auto document = QJsonDocument::fromJson(output);
           const auto labelId =
               document.object().value(QStringLiteral("id")).toInteger();
           if (!document.isObject() || labelId <= 0) {
             emit saveFailed(QStringLiteral("Invalid created Vikunja label"));
             refreshAfterMutation();
             return;
           }

           operation->labels.insert(tag, labelId);
           attachSaveLabel(operation, labelId);
         });
}

void Tasks::attachSaveLabel(const std::shared_ptr<SaveOperation> &operation,
                            qint64 labelId) {
  runCli({QStringLiteral("tasks"), QStringLiteral("labels"),
          QStringLiteral("add"), QStringLiteral("--task-id"),
          operation->taskId, QStringLiteral("--label-id"),
          QString::number(labelId)},
         [this, operation](bool succeeded, const QByteArray &,
                           const QString &error) {
           if (!succeeded) {
             emit saveFailed(error);
             refreshAfterMutation();
             return;
           }

           ++operation->index;
           continueSave(operation);
         });
}

bool Tasks::setTodoStatus(int index, const QString &marker) {
  const auto taskId = taskIdAt(m_todos, index);
  const auto markerValue = marker.left(1);
  if (taskId.isEmpty() || markerValue.isEmpty())
    return false;

  QStringList arguments;
  if (markerValue == QStringLiteral("-")) {
    arguments = {QStringLiteral("tasks"), QStringLiteral("delete"),
                 QStringLiteral("--id"), taskId};
  } else {
    arguments = {QStringLiteral("tasks"), QStringLiteral("update"),
                 QStringLiteral("--id"), taskId};
    if (markerValue == QStringLiteral("x")) {
      arguments.append(QStringLiteral("--done"));
    } else if (markerValue == QStringLiteral("/")) {
      arguments.append({QStringLiteral("--done=false"),
                        QStringLiteral("--percent-done"),
                        QStringLiteral("0.5"), QStringLiteral("--priority"),
                        QStringLiteral("0")});
    } else if (markerValue == QStringLiteral(">")) {
      arguments.append({QStringLiteral("--done=false"),
                        QStringLiteral("--due-date"),
                        dueDateFor(QDate::currentDate().addDays(1)),
                        QStringLiteral("--percent-done"), QStringLiteral("0"),
                        QStringLiteral("--priority"), QStringLiteral("0")});
    } else if (markerValue == QStringLiteral("?")) {
      arguments.append({QStringLiteral("--done=false"),
                        QStringLiteral("--percent-done"), QStringLiteral("0"),
                        QStringLiteral("--priority"), QStringLiteral("1")});
    } else if (markerValue == QStringLiteral("!")) {
      arguments.append({QStringLiteral("--done=false"),
                        QStringLiteral("--percent-done"), QStringLiteral("0"),
                        QStringLiteral("--priority"), QStringLiteral("5")});
    } else {
      arguments.append({QStringLiteral("--done=false"),
                        QStringLiteral("--percent-done"), QStringLiteral("0"),
                        QStringLiteral("--priority"), QStringLiteral("0")});
    }
  }

  runCli(arguments, [this](bool succeeded, const QByteArray &,
                           const QString &error) {
    if (!succeeded) {
      emit operationFailed(error);
      return;
    }
    refreshAfterMutation();
  });
  return true;
}

bool Tasks::annotateTodo(int index, const QString &note) {
  const auto taskId = taskIdAt(m_todos, index);
  const auto comment = note.trimmed();
  if (taskId.isEmpty() || comment.isEmpty())
    return false;

  runCli({QStringLiteral("tasks"), QStringLiteral("comments"),
          QStringLiteral("create"), QStringLiteral("--task-id"), taskId,
          QStringLiteral("--comment"), comment},
         [this](bool succeeded, const QByteArray &, const QString &error) {
           if (!succeeded) {
             emit operationFailed(error);
             return;
           }
           fetchTodos();
         });
  return true;
}

bool Tasks::appendSessionLog(const QString &noteId, int focusMinutes,
                             int breakMinutes, const QVariantList &events) {
  if (noteId.isEmpty() || events.isEmpty())
    return false;

  QStringList lines = {
      QStringLiteral("Time: %1 min").arg(focusMinutes),
      QStringLiteral("Break time: %1 min").arg(breakMinutes)};
  for (const auto &event : events) {
    const auto map = event.toMap();
    const auto line =
        QStringLiteral("%1 %2")
            .arg(map.value(QStringLiteral("time")).toString(),
                 map.value(QStringLiteral("text")).toString())
            .trimmed();
    if (!line.isEmpty())
      lines.append(line);
  }

  runCli({QStringLiteral("tasks"), QStringLiteral("comments"),
          QStringLiteral("create"), QStringLiteral("--task-id"), noteId,
          QStringLiteral("--comment"), lines.join(QStringLiteral(" | "))},
         [this](bool succeeded, const QByteArray &, const QString &error) {
           if (!succeeded) {
             emit operationFailed(error);
             return;
           }
           fetchTodos();
         });
  return true;
}

void Tasks::refreshAfterMutation() {
  fetchTodos();
  fetchTags();
}
