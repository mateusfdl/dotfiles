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

ObsidianTodo::ObsidianTodo(QObject* parent) : QObject(parent) {}

QStringList ObsidianTodo::tags() const { return m_tags; }

QVariantList ObsidianTodo::todos() const { return m_todos; }

bool ObsidianTodo::saving() const { return m_saving; }

void ObsidianTodo::setSaving(bool v) {
    if (m_saving == v) return;
    m_saving = v;
    emit savingChanged();
}

void ObsidianTodo::fetchTags() {
    auto* proc = new QProcess(this);
    proc->setProgram(OBSIDIAN_BIN);
    proc->setArguments({QStringLiteral("vault=Personal"), QStringLiteral("tags"),
                        QStringLiteral("counts"), QStringLiteral("format=json")});

    connect(proc, &QProcess::errorOccurred, this,
            [proc](QProcess::ProcessError) { proc->deleteLater(); });

    connect(proc, &QProcess::finished, this,
            [this, proc](int exitCode, QProcess::ExitStatus) {
                proc->deleteLater();
                if (exitCode != 0) return;

                const auto data = proc->readAllStandardOutput();
                const auto doc = QJsonDocument::fromJson(data);
                if (!doc.isArray()) return;

                struct TagEntry {
                    QString name;
                    int count = 0;
                };
                std::vector<TagEntry> entries;

                for (const auto& val : doc.array()) {
                    const auto obj = val.toObject();
                    auto tag = obj.value(QStringLiteral("tag")).toString();
                    if (tag.startsWith(QLatin1Char('#')))
                        tag = tag.mid(1);
                    int count = obj.value(QStringLiteral("count")).toString().toInt();
                    entries.push_back({std::move(tag), count});
                }

                std::sort(entries.begin(), entries.end(),
                          [](const TagEntry& a, const TagEntry& b) {
                              return a.count > b.count;
                          });

                QStringList result;
                result.reserve(static_cast<int>(entries.size()));
                for (auto& e : entries)
                    result.append(std::move(e.name));

                if (result != m_tags) {
                    m_tags = std::move(result);
                    emit tagsChanged();
                }
            });

    proc->start(QProcess::ReadOnly);
}

void ObsidianTodo::fetchTodos() {
    const QString date = QDate::currentDate().toString(QStringLiteral("yyyy-MM-dd"));
    const QString journalPath =
        QStringLiteral("%1/Journal/%2.md").arg(QLatin1String(VAULT_PATH), date);

    QFile file(journalPath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        if (m_todos != QVariantList{}) {
            m_todos.clear();
            emit todosChanged();
        }
        return;
    }

    const QString content = QTextStream(&file).readAll();
    file.close();

    // Find the # TODO section
    int todoIdx = content.indexOf(QStringLiteral("# TODO"));
    if (todoIdx == -1) {
        if (m_todos != QVariantList{}) {
            m_todos.clear();
            emit todosChanged();
        }
        return;
    }

    // Find the end of the TODO section (next heading or separator)
    int sectionEnd = content.length();
    int searchFrom = todoIdx + 6;
    int separatorIdx = content.indexOf(QStringLiteral("\n___"), searchFrom);
    int nextSectionIdx = content.indexOf(QStringLiteral("\n# "), searchFrom);

    if (separatorIdx != -1 && nextSectionIdx != -1)
        sectionEnd = std::min(separatorIdx, nextSectionIdx);
    else if (separatorIdx != -1)
        sectionEnd = separatorIdx;
    else if (nextSectionIdx != -1)
        sectionEnd = nextSectionIdx;

    const QString todoSection = content.mid(todoIdx, sectionEnd - todoIdx);

    // Parse unchecked todo lines: - [ ] description [[noteId]] #tag1 #tag2
    static const QRegularExpression todoLineRe(
        QStringLiteral(R"(^- \[ \] (.+)$)"),
        QRegularExpression::MultilineOption);

    static const QRegularExpression wikiLinkRe(
        QStringLiteral(R"(\[\[([^\]]+)\]\])"));

    static const QRegularExpression tagRe(
        QStringLiteral(R"(#([\w-]+))"));

    QVariantList result;

    auto it = todoLineRe.globalMatch(todoSection);
    while (it.hasNext()) {
        auto match = it.next();
        QString fullLine = match.captured(1).trimmed();

        // Extract noteId from [[wikilink]]
        QString noteId;
        auto linkMatch = wikiLinkRe.match(fullLine);
        if (linkMatch.hasMatch()) {
            noteId = linkMatch.captured(1);
        }

        // Extract tags
        QStringList tags;
        auto tagIt = tagRe.globalMatch(fullLine);
        while (tagIt.hasNext()) {
            auto tagMatch = tagIt.next();
            tags.append(tagMatch.captured(1));
        }

        // Extract description: remove [[...]] and #tags from the line
        QString description = fullLine;
        description.remove(wikiLinkRe);
        description.remove(tagRe);
        description = description.trimmed();

        QVariantMap entry;
        entry[QStringLiteral("description")] = description;
        entry[QStringLiteral("noteId")] = noteId;
        entry[QStringLiteral("tags")] = tags;
        result.append(entry);
    }

    if (result != m_todos) {
        m_todos = std::move(result);
        emit todosChanged();
    }
}

QString ObsidianTodo::generateSlug(const QString& text) {
    static const QRegularExpression nonAlnum(QStringLiteral("[^a-z0-9\\s]"));
    static const QRegularExpression whitespace(QStringLiteral("\\s+"));

    QString lower = text.toLower().trimmed();
    lower.remove(nonAlnum);

    QStringList words = lower.split(whitespace, Qt::SkipEmptyParts);
    if (words.size() > 5)
        words = words.mid(0, 5);

    return words.join(QLatin1Char('-'));
}

bool ObsidianTodo::writeNoteFile(const QString& slug, const QString& timestamp,
                                  const QString& date, const QString& description,
                                  [[maybe_unused]] const QStringList& tags) {
    const QString dirPath =
        QStringLiteral("%1/Journal/todos").arg(QLatin1String(VAULT_PATH));
    QDir dir(dirPath);
    if (!dir.exists())
        dir.mkpath(QStringLiteral("."));

    const QString fileName =
        QStringLiteral("%1-%2.md").arg(timestamp, slug);
    const QString filePath = dir.filePath(fileName);

    QFile file(filePath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
        return false;

    QTextStream out(&file);
    out << QStringLiteral("---\n");
    out << QStringLiteral("id: %1-%2\n").arg(timestamp, slug);
    out << QStringLiteral("date: %1\n").arg(date);
    out << QStringLiteral("hubs:\n  - \n");
    out << QStringLiteral("tags:\n  - TODO\n");
    out << QStringLiteral("refs:\n");
    out << QStringLiteral("status: pending\n");
    out << QStringLiteral("---\n");
    out << description << QStringLiteral("\n");

    file.close();
    return true;
}

bool ObsidianTodo::insertIntoDailyJournal(const QString& slug,
                                           const QString& description,
                                           const QStringList& tags) {
    const QString date = QDate::currentDate().toString(QStringLiteral("yyyy-MM-dd"));
    const QString journalPath =
        QStringLiteral("%1/Journal/%2.md").arg(QLatin1String(VAULT_PATH), date);

    QFile file(journalPath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return false;

    const QString content = QTextStream(&file).readAll();
    file.close();

    QString tagStr;
    for (const auto& t : tags)
        tagStr += QStringLiteral(" #%1").arg(t);

    const QString todoLine =
        QStringLiteral("- [ ] %1 [[%2]]%3")
            .arg(description, slug, tagStr);

    int todoIdx = content.indexOf(QStringLiteral("# TODO"));
    if (todoIdx == -1)
        return false;

    int insertPos = -1;
    int searchFrom = todoIdx + 6;

    int separatorIdx = content.indexOf(QStringLiteral("\n___"), searchFrom);
    int nextSectionIdx = content.indexOf(QStringLiteral("\n# "), searchFrom);

    if (separatorIdx != -1 && nextSectionIdx != -1)
        insertPos = std::min(separatorIdx, nextSectionIdx);
    else if (separatorIdx != -1)
        insertPos = separatorIdx;
    else if (nextSectionIdx != -1)
        insertPos = nextSectionIdx;
    else
        insertPos = content.length();

    QString modified = content;
    modified.insert(insertPos, QStringLiteral("\n") + todoLine);

    if (!file.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate))
        return false;

    QTextStream out(&file);
    out << modified;
    file.close();
    return true;
}

void ObsidianTodo::saveTodo(const QString& description, const QStringList& tags) {
    if (description.trimmed().isEmpty()) {
        emit saveFailed(QStringLiteral("Empty description"));
        return;
    }

    setSaving(true);

    const auto now = QDateTime::currentDateTime();
    const QString timestamp = now.toString(QStringLiteral("yyyyMMddHHmm"));
    const QString date = now.date().toString(QStringLiteral("yyyy-MM-dd"));
    const QString slug = generateSlug(description);
    const QString noteSlug = QStringLiteral("%1-%2").arg(timestamp, slug);

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

QString ObsidianTodo::ensureNoteFile(const QString& description, const QStringList& tags) {
    if (description.trimmed().isEmpty())
        return {};

    const auto now = QDateTime::currentDateTime();
    const QString timestamp = now.toString(QStringLiteral("yyyyMMddHHmm"));
    const QString date = now.date().toString(QStringLiteral("yyyy-MM-dd"));
    const QString slug = generateSlug(description);
    const QString noteId = QStringLiteral("%1-%2").arg(timestamp, slug);

    // Check if the note file already exists (shouldn't, but be safe)
    const QString dirPath =
        QStringLiteral("%1/Journal/todos").arg(QLatin1String(VAULT_PATH));
    const QString filePath =
        QStringLiteral("%1/%2.md").arg(dirPath, noteId);

    if (QFile::exists(filePath))
        return noteId;

    if (!writeNoteFile(slug, timestamp, date, description, tags))
        return {};

    // Update the daily journal line to include the [[wikilink]]
    updateJournalTodoLink(description, noteId);

    return noteId;
}

bool ObsidianTodo::updateJournalTodoLink(const QString& description,
                                          const QString& noteId) {
    const QString date = QDate::currentDate().toString(QStringLiteral("yyyy-MM-dd"));
    const QString journalPath =
        QStringLiteral("%1/Journal/%2.md").arg(QLatin1String(VAULT_PATH), date);

    QFile file(journalPath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return false;

    QString content = QTextStream(&file).readAll();
    file.close();

    // Find the unchecked todo line matching the description (without a wikilink)
    // We look for "- [ ] <description>" that does NOT already contain [[...]]
    // Match the exact description text in the line
    int searchPos = 0;
    const QString prefix = QStringLiteral("- [ ] ");
    while (true) {
        int idx = content.indexOf(prefix + description, searchPos);
        if (idx == -1)
            break;

        // Check this line doesn't already have a [[wikilink]]
        int lineEnd = content.indexOf(QLatin1Char('\n'), idx);
        if (lineEnd == -1)
            lineEnd = content.length();
        const QString line = content.mid(idx, lineEnd - idx);

        if (!line.contains(QStringLiteral("[["))) {
            // Insert [[noteId]] right after the description, before any #tags
            // Find first # tag in the line after description
            static const QRegularExpression firstTagRe(QStringLiteral(R"(\s+#[\w-]+)"));
            auto tagMatch = firstTagRe.match(line);
            int insertOffset;
            if (tagMatch.hasMatch()) {
                insertOffset = idx + tagMatch.capturedStart();
            } else {
                insertOffset = lineEnd;
            }
            content.insert(insertOffset, QStringLiteral(" [[%1]]").arg(noteId));

            if (!file.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate))
                return false;
            QTextStream out(&file);
            out << content;
            file.close();
            return true;
        }

        searchPos = lineEnd;
    }

    return false; // no matching line found
}

bool ObsidianTodo::appendSessionLog(const QString& noteId, int focusMinutes,
                                     int breakMinutes, const QVariantList& events) {
    if (noteId.isEmpty() || events.isEmpty())
        return false;

    const QString filePath =
        QStringLiteral("%1/Journal/todos/%2.md").arg(QLatin1String(VAULT_PATH), noteId);

    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return false;

    QString content = QTextStream(&file).readAll();
    file.close();

    const QString today = QDate::currentDate().toString(QStringLiteral("yyyy-MM-dd"));

    // Build the log block
    QString logBlock;
    QTextStream lb(&logBlock);
    lb << QStringLiteral("__Time__: %1 min\n").arg(focusMinutes);
    lb << QStringLiteral("__Break time__: %1 min\n").arg(breakMinutes);
    lb << QStringLiteral("\n==== logs ====\n");
    for (const auto& ev : events) {
        const auto map = ev.toMap();
        lb << map.value(QStringLiteral("time")).toString()
           << QStringLiteral(" ")
           << map.value(QStringLiteral("text")).toString()
           << QStringLiteral("\n");
    }
    lb << QStringLiteral("==============\n");

    // Check if # Sessions heading exists
    int sessionsIdx = content.indexOf(QStringLiteral("# Sessions"));

    if (sessionsIdx == -1) {
        // No sessions section yet — append at end of file
        if (!content.endsWith(QLatin1Char('\n')))
            content += QLatin1Char('\n');
        content += QStringLiteral("\n# Sessions\n\n");
        content += QStringLiteral("## %1\n\n").arg(today);
        content += logBlock;
    } else {
        // Sessions section exists — check for today's date heading
        const QString dateHeading = QStringLiteral("## %1").arg(today);
        int dateIdx = content.indexOf(dateHeading, sessionsIdx);

        if (dateIdx != -1) {
            // Today's heading exists — find the end of today's section
            // (next ## heading or end of file)
            int insertPos = content.length();
            int nextDateIdx = content.indexOf(QStringLiteral("\n## "), dateIdx + dateHeading.length());
            if (nextDateIdx != -1)
                insertPos = nextDateIdx;

            // Insert the log block before the next date section (or at end)
            QString insertion;
            if (!content.mid(insertPos - 1, 1).endsWith(QLatin1Char('\n')))
                insertion += QLatin1Char('\n');
            insertion += logBlock;
            content.insert(insertPos, insertion);
        } else {
            // No today's heading — append it at the end of the sessions section
            if (!content.endsWith(QLatin1Char('\n')))
                content += QLatin1Char('\n');
            content += QStringLiteral("\n## %1\n\n").arg(today);
            content += logBlock;
        }
    }

    if (!file.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate))
        return false;
    QTextStream out(&file);
    out << content;
    file.close();
    return true;
}
