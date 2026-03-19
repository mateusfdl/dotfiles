#pragma once

#include <QObject>
#include <QProcess>
#include <QString>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>

class ObsidianTodo : public QObject {
  Q_OBJECT
  QML_ELEMENT
  QML_SINGLETON
  Q_PROPERTY(QStringList tags READ tags NOTIFY tagsChanged)
  Q_PROPERTY(QVariantList todos READ todos NOTIFY todosChanged)
  Q_PROPERTY(bool saving READ saving NOTIFY savingChanged)

public:
  explicit ObsidianTodo(QObject *parent = nullptr);

  QStringList tags() const;
  QVariantList todos() const;
  bool saving() const;

  Q_INVOKABLE void fetchTags();
  Q_INVOKABLE void fetchTodos();
  Q_INVOKABLE void saveTodo(const QString &description,
                            const QStringList &tags);
  Q_INVOKABLE static QString generateSlug(const QString &text);
  Q_INVOKABLE QString ensureNoteFile(const QString &description,
                                     const QStringList &tags);
  Q_INVOKABLE bool appendSessionLog(const QString &noteId, int focusMinutes,
                                    int breakMinutes,
                                    const QVariantList &events);

signals:
  void tagsChanged();
  void todosChanged();
  void savingChanged();
  void saved();
  void saveFailed(const QString &error);

private:
  void setSaving(bool v);

  bool writeNoteFile(const QString &slug, const QString &timestamp,
                     const QString &date, const QString &description,
                     const QStringList &tags);
  bool insertIntoDailyJournal(const QString &slug, const QString &description,
                              const QStringList &tags);
  bool updateJournalTodoLink(const QString &description, const QString &noteId);

  static QString journalPathForToday();
  static QString readFileContent(const QString &path);
  static bool writeFileContent(const QString &path, const QString &content);
  static int findSectionEnd(const QString &content, int sectionStart);

  QStringList m_tags;
  QVariantList m_todos;
  bool m_saving = false;

  static constexpr const char *VAULT_PATH =
      "/home/matheus/Documents/personal-org-mode/Personal";
  static constexpr const char *OBSIDIAN_BIN =
      "/etc/profiles/per-user/matheus/bin/obsidian";
};
