#pragma once

#include <QObject>
#include <QProcess>
#include <QString>
#include <QStringList>
#include <QtQml/qqmlregistration.h>

class ObsidianTodo : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(QStringList tags READ tags NOTIFY tagsChanged)
    Q_PROPERTY(bool saving READ saving NOTIFY savingChanged)

public:
    explicit ObsidianTodo(QObject* parent = nullptr);

    QStringList tags() const;
    bool saving() const;

    Q_INVOKABLE void fetchTags();
    Q_INVOKABLE void saveTodo(const QString& description, const QStringList& tags);
    Q_INVOKABLE static QString generateSlug(const QString& text);

signals:
    void tagsChanged();
    void savingChanged();
    void saved();
    void saveFailed(const QString& error);

private:
    void setSaving(bool v);
    bool writeNoteFile(const QString& slug, const QString& timestamp,
                       const QString& date, const QString& description,
                       const QStringList& tags);
    bool insertIntoDailyJournal(const QString& slug, const QString& description,
                                const QStringList& tags);

    QStringList m_tags;
    bool m_saving = false;

    static constexpr const char* VAULT_PATH =
        "/home/matheus/Documents/personal-org-mode/Personal";
    static constexpr const char* OBSIDIAN_BIN = "/etc/profiles/per-user/matheus/bin/obsidian";
};
