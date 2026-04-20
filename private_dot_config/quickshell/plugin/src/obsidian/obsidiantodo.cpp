#include "obsidiantodo.hpp"

#include <QDate>
#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>
#include <QTextStream>
#include <QTime>

#include <algorithm>

ObsidianTodo::ObsidianTodo(QObject *parent) : QObject(parent) {}

QStringList ObsidianTodo::tags() const { return m_tags; }

QVariantList ObsidianTodo::todos() const { return m_todos; }

bool ObsidianTodo::saving() const { return m_saving; }

void ObsidianTodo::setSaving(bool v) {
  if (m_saving == v)
    return;
  m_saving = v;
  emit savingChanged();
}

QString ObsidianTodo::journalPathForToday() {
  const auto date = QDate::currentDate().toString(QStringLiteral("yyyy-MM-dd"));
  return QStringLiteral("%1/Journal/%2.md")
      .arg(QLatin1String(VAULT_PATH), date);
}

QString ObsidianTodo::readFileContent(const QString &path) {
  QFile file(path);
  if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
    return {};
  return QTextStream(&file).readAll();
}

bool ObsidianTodo::writeFileContent(const QString &path,
                                    const QString &content) {
  QFile file(path);
  if (!file.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate))
    return false;
  QTextStream(&file) << content;
  return true;
}

int ObsidianTodo::findSectionEnd(const QString &content, int sectionStart) {
  const int searchFrom = sectionStart + 6;
  const int separatorIdx = content.indexOf(QStringLiteral("\n___"), searchFrom);
  const int nextSectionIdx =
      content.indexOf(QStringLiteral("\n# "), searchFrom);

  if (separatorIdx != -1 && nextSectionIdx != -1)
    return std::min(separatorIdx, nextSectionIdx);
  if (separatorIdx != -1)
    return separatorIdx;
  if (nextSectionIdx != -1)
    return nextSectionIdx;

  return content.length();
}

void ObsidianTodo::fetchTags() {
  auto *proc = new QProcess(this);
  proc->setProgram(OBSIDIAN_BIN);
  proc->setArguments({QStringLiteral("vault=Personal"), QStringLiteral("tags"),
                      QStringLiteral("counts"), QStringLiteral("format=json")});

  connect(proc, &QProcess::errorOccurred, this,
          [proc](QProcess::ProcessError) { proc->deleteLater(); });

  connect(proc, &QProcess::finished, this,
          [this, proc](int exitCode, QProcess::ExitStatus) {
            proc->deleteLater();
            if (exitCode != 0)
              return;

            const auto data = proc->readAllStandardOutput();
            const auto doc = QJsonDocument::fromJson(data);
            if (!doc.isArray())
              return;

            struct TagEntry {
              QString name;
              int count = 0;
            };
            std::vector<TagEntry> entries;

            for (const auto &val : doc.array()) {
              const auto obj = val.toObject();
              auto tag = obj.value(QStringLiteral("tag")).toString();
              if (tag.startsWith(QLatin1Char('#')))
                tag = tag.mid(1);
              const int count =
                  obj.value(QStringLiteral("count")).toString().toInt();
              entries.push_back({std::move(tag), count});
            }

            std::sort(entries.begin(), entries.end(),
                      [](const TagEntry &a, const TagEntry &b) {
                        return a.count > b.count;
                      });

            QStringList result;
            result.reserve(static_cast<int>(entries.size()));
            for (auto &e : entries)
              result.append(std::move(e.name));

            if (result != m_tags) {
              m_tags = std::move(result);
              emit tagsChanged();
            }
          });

  proc->start(QProcess::ReadOnly);
}

void ObsidianTodo::fetchTodos() {
  const auto journalPath = journalPathForToday();

  const auto content = readFileContent(journalPath);
  if (content.isNull()) {
    if (!m_todos.isEmpty()) {
      m_todos.clear();
      emit todosChanged();
    }
    return;
  }

  const int todoIdx = content.indexOf(QStringLiteral("# TODO"));
  if (todoIdx == -1) {
    if (!m_todos.isEmpty()) {
      m_todos.clear();
      emit todosChanged();
    }
    return;
  }

  const int sectionEnd = findSectionEnd(content, todoIdx);
  const auto todoSection = content.mid(todoIdx, sectionEnd - todoIdx);

  static const QRegularExpression todoLineRe(
      QStringLiteral(R"(^- \[(.)\] (.+)$)"),
      QRegularExpression::MultilineOption);

  static const QRegularExpression wikiLinkRe(
      QStringLiteral(R"(\[\[([^\]]+)\]\])"));

  static const QRegularExpression tagRe(QStringLiteral(R"(#([\w-]+))"));

  QVariantList result;

  auto it = todoLineRe.globalMatch(todoSection);
  while (it.hasNext()) {
    const auto match = it.next();
    const auto statusMarker = match.captured(1);
    const auto fullLine = match.captured(2).trimmed();

    QString noteId;
    const auto linkMatch = wikiLinkRe.match(fullLine);
    if (linkMatch.hasMatch())
      noteId = linkMatch.captured(1);

    QStringList lineTags;
    auto tagIt = tagRe.globalMatch(fullLine);
    while (tagIt.hasNext())
      lineTags.append(tagIt.next().captured(1));

    auto description = fullLine;
    description.remove(wikiLinkRe);
    description.remove(tagRe);
    description = description.trimmed();

    QVariantMap entry;
    entry[QStringLiteral("status")] = statusMarker;
    entry[QStringLiteral("description")] = description;
    entry[QStringLiteral("noteId")] = noteId;
    entry[QStringLiteral("tags")] = lineTags;
    result.append(entry);
  }

  if (result != m_todos) {
    m_todos = std::move(result);
    emit todosChanged();
  }
}

QString ObsidianTodo::generateSlug(const QString &text) {
  static const QRegularExpression nonAlnum(QStringLiteral("[^a-z0-9\\s]"));
  static const QRegularExpression whitespace(QStringLiteral("\\s+"));

  auto lower = text.toLower().trimmed();
  lower.remove(nonAlnum);

  auto words = lower.split(whitespace, Qt::SkipEmptyParts);
  if (words.size() > 5)
    words = words.mid(0, 5);

  return words.join(QLatin1Char('-'));
}

bool ObsidianTodo::writeNoteFile(const QString &slug, const QString &timestamp,
                                 const QString &date,
                                 const QString &description,
                                 [[maybe_unused]] const QStringList &tags) {
  const auto dirPath =
      QStringLiteral("%1/Journal/todos").arg(QLatin1String(VAULT_PATH));
  QDir dir(dirPath);
  if (!dir.exists())
    dir.mkpath(QStringLiteral("."));

  const auto filePath =
      dir.filePath(QStringLiteral("%1-%2.md").arg(timestamp, slug));

  QFile file(filePath);
  if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
    return false;

  QTextStream out(&file);
  out << QStringLiteral("---\n")
      << QStringLiteral("id: %1-%2\n").arg(timestamp, slug)
      << QStringLiteral("date: %1\n").arg(date)
      << QStringLiteral("hubs:\n  - \n") << QStringLiteral("tags:\n  - TODO\n")
      << QStringLiteral("refs:\n") << QStringLiteral("status: pending\n")
      << QStringLiteral("---\n") << description << QStringLiteral("\n");

  return true;
}

bool ObsidianTodo::insertIntoDailyJournal(const QString &slug,
                                          const QString &description,
                                          const QStringList &tags) {
  const auto journalPath = journalPathForToday();
  auto content = readFileContent(journalPath);
  if (content.isNull())
    return false;

  QStringList tagParts;
  tagParts.reserve(tags.size());
  for (const auto &t : tags)
    tagParts.append(QStringLiteral("#%1").arg(t));

  const auto tagStr = tagParts.isEmpty() ? QString()
                                         : QStringLiteral(" ") +
                                               tagParts.join(QLatin1Char(' '));

  const auto todoLine =
      QStringLiteral("- [ ] %1 [[%2]]%3").arg(description, slug, tagStr);

  const int todoIdx = content.indexOf(QStringLiteral("# TODO"));
  if (todoIdx == -1)
    return false;

  const int insertPos = findSectionEnd(content, todoIdx);
  content.insert(insertPos, QStringLiteral("\n") + todoLine);

  return writeFileContent(journalPath, content);
}

void ObsidianTodo::saveTodo(const QString &description,
                            const QStringList &tags) {
  if (description.trimmed().isEmpty()) {
    emit saveFailed(QStringLiteral("Empty description"));
    return;
  }

  setSaving(true);

  const auto now = QDateTime::currentDateTime();
  const auto timestamp = now.toString(QStringLiteral("yyyyMMddHHmm"));
  const auto date = now.date().toString(QStringLiteral("yyyy-MM-dd"));
  const auto slug = generateSlug(description);
  const auto noteSlug = QStringLiteral("%1-%2").arg(timestamp, slug);

  if (!writeNoteFile(slug, timestamp, date, description, tags)) {
    setSaving(false);
    emit saveFailed(QStringLiteral("Failed to write note file"));
    return;
  }

  if (!insertIntoDailyJournal(noteSlug, description, tags)) {
    setSaving(false);
    emit saveFailed(QStringLiteral("Failed to insert into daily journal"));
    return;
  }

  setSaving(false);
  emit saved();
}

QString ObsidianTodo::ensureNoteFile(const QString &description,
                                     const QStringList &tags) {
  if (description.trimmed().isEmpty())
    return {};

  const auto now = QDateTime::currentDateTime();
  const auto timestamp = now.toString(QStringLiteral("yyyyMMddHHmm"));
  const auto date = now.date().toString(QStringLiteral("yyyy-MM-dd"));
  const auto slug = generateSlug(description);
  const auto noteId = QStringLiteral("%1-%2").arg(timestamp, slug);

  const auto dirPath =
      QStringLiteral("%1/Journal/todos").arg(QLatin1String(VAULT_PATH));
  const auto filePath = QStringLiteral("%1/%2.md").arg(dirPath, noteId);

  if (QFile::exists(filePath))
    return noteId;

  if (!writeNoteFile(slug, timestamp, date, description, tags))
    return {};

  updateJournalTodoLink(description, noteId);

  return noteId;
}

bool ObsidianTodo::updateJournalTodoLink(const QString &description,
                                         const QString &noteId) {
  const auto journalPath = journalPathForToday();
  auto content = readFileContent(journalPath);
  if (content.isNull())
    return false;

  int searchPos = 0;
  const auto prefix = QStringLiteral("- [ ] ");

  while (true) {
    const int idx = content.indexOf(prefix + description, searchPos);
    if (idx == -1)
      break;

    int lineEnd = content.indexOf(QLatin1Char('\n'), idx);
    if (lineEnd == -1)
      lineEnd = content.length();

    const auto line = content.mid(idx, lineEnd - idx);

    if (!line.contains(QStringLiteral("[["))) {
      static const QRegularExpression firstTagRe(
          QStringLiteral(R"(\s+#[\w-]+)"));
      const auto tagMatch = firstTagRe.match(line);
      const int insertOffset =
          tagMatch.hasMatch() ? idx + tagMatch.capturedStart() : lineEnd;

      content.insert(insertOffset, QStringLiteral(" [[%1]]").arg(noteId));
      return writeFileContent(journalPath, content);
    }

    searchPos = lineEnd;
  }

  return false;
}

bool ObsidianTodo::setTodoStatus(int index, const QString &marker) {
  if (index < 0 || marker.isEmpty())
    return false;

  const auto journalPath = journalPathForToday();
  auto content = readFileContent(journalPath);
  if (content.isNull())
    return false;

  const int todoIdx = content.indexOf(QStringLiteral("# TODO"));
  if (todoIdx == -1)
    return false;

  const int sectionEnd = findSectionEnd(content, todoIdx);
  const auto todoSection = content.mid(todoIdx, sectionEnd - todoIdx);

  static const QRegularExpression todoLineRe(
      QStringLiteral(R"(^- \[(.)\] (.+)$)"),
      QRegularExpression::MultilineOption);

  int current = 0;
  auto it = todoLineRe.globalMatch(todoSection);
  while (it.hasNext()) {
    const auto match = it.next();
    if (current == index) {
      const int absStart = todoIdx + match.capturedStart();
      const int bracketContentPos = absStart + 3;
      content.replace(bracketContentPos, 1, marker);
      if (!writeFileContent(journalPath, content))
        return false;
      fetchTodos();
      return true;
    }
    ++current;
  }

  return false;
}

bool ObsidianTodo::appendSessionLog(const QString &noteId, int focusMinutes,
                                    int breakMinutes,
                                    const QVariantList &events) {
  if (noteId.isEmpty() || events.isEmpty())
    return false;

  const auto filePath = QStringLiteral("%1/Journal/todos/%2.md")
                            .arg(QLatin1String(VAULT_PATH), noteId);

  auto content = readFileContent(filePath);
  if (content.isNull())
    return false;

  const auto today =
      QDate::currentDate().toString(QStringLiteral("yyyy-MM-dd"));

  QString logBlock;
  QTextStream lb(&logBlock);
  lb << QStringLiteral("__Time__: %1 min\n").arg(focusMinutes)
     << QStringLiteral("__Break time__: %1 min\n").arg(breakMinutes)
     << QStringLiteral("\n==== logs ====\n");

  for (const auto &ev : events) {
    const auto map = ev.toMap();
    lb << map.value(QStringLiteral("time")).toString() << QStringLiteral(" ")
       << map.value(QStringLiteral("text")).toString() << QStringLiteral("\n");
  }
  lb << QStringLiteral("==============\n");

  const int sessionsIdx = content.indexOf(QStringLiteral("# Sessions"));

  if (sessionsIdx == -1) {
    if (!content.endsWith(QLatin1Char('\n')))
      content += QLatin1Char('\n');
    content += QStringLiteral("\n# Sessions\n\n");
    content += QStringLiteral("## %1\n\n").arg(today);
    content += logBlock;
  } else {
    const auto dateHeading = QStringLiteral("## %1").arg(today);
    const int dateIdx = content.indexOf(dateHeading, sessionsIdx);

    if (dateIdx != -1) {
      int insertPos = content.length();
      const int nextDateIdx = content.indexOf(QStringLiteral("\n## "),
                                              dateIdx + dateHeading.length());
      if (nextDateIdx != -1)
        insertPos = nextDateIdx;

      QString insertion;
      if (insertPos > 0 && content[insertPos - 1] != QLatin1Char('\n'))
        insertion += QLatin1Char('\n');
      insertion += logBlock;
      content.insert(insertPos, insertion);
    } else {
      if (!content.endsWith(QLatin1Char('\n')))
        content += QLatin1Char('\n');
      content += QStringLiteral("\n## %1\n\n").arg(today);
      content += logBlock;
    }
  }

  return writeFileContent(filePath, content);
}
