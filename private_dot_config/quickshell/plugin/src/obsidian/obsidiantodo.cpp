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

#include <algorithm>

ObsidianTodo::ObsidianTodo(QObject* parent) : QObject(parent) {}

QStringList ObsidianTodo::tags() const { return m_tags; }

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
