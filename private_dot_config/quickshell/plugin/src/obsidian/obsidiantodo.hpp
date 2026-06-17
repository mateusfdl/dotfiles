#pragma once

#include <QObject>
#include <QProcess>
#include <QString>
#include <QStringList>
#include <QVariantList>
#include <QtQml/qqmlregistration.h>

class ObsidianTodo : public QObject {
  Q_OBJECT
  QML_ELEMENT
  QML_SINGLETON
  Q_PROPERTY(QStringList tags READ tags NOTIFY tagsChanged)
  Q_PROPERTY(QVariantList todos READ todos NOTIFY todosChanged)

public:
  explicit ObsidianTodo(QObject *parent = nullptr);

  QStringList tags() const;
  QVariantList todos() const;

  Q_INVOKABLE void fetchTags();
  Q_INVOKABLE void fetchTodos();
  Q_INVOKABLE void saveTodo(const QString &description,
                            const QStringList &tags);
  Q_INVOKABLE QString ensureNoteFile(const QString &description,
                                     const QStringList &tags);
  Q_INVOKABLE bool appendSessionLog(const QString &noteId, int focusMinutes,
                                    int breakMinutes,
                                    const QVariantList &events);
  Q_INVOKABLE bool setTodoStatus(int index, const QString &marker);
  Q_INVOKABLE bool annotateTodo(int index, const QString &note);

signals:
  void tagsChanged();
  void todosChanged();
  void saved();
  void saveFailed(const QString &error);

private:
  static QStringList taskArguments(const QStringList &arguments);
  static QProcess *startTask(QObject *parent, const QStringList &arguments);
  static QByteArray runTask(const QStringList &arguments, bool *ok);
  static QString normalizeTag(const QString &tag);
  static QString markerFromTask(const QVariantMap &task);
  static QVariantList parseTodos(const QByteArray &data);
  static QStringList parseTags(const QByteArray &data);
  static QString uuidForTodo(const QVariantMap &todo);

  QStringList m_tags;
  QVariantList m_todos;

  static constexpr const char *TASKWARRIOR_BIN =
      "/home/matheus/Documents/personal-org-mode/Personal/Journal/todos/taskw";
};
