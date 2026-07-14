#pragma once

#include <QObject>
#include <QProcess>
#include <QString>
#include <QStringList>
#include <QVariantList>
#include <QtQml/qqmlregistration.h>

class Tasks : public QObject {
  Q_OBJECT
  QML_ELEMENT
  QML_SINGLETON
  Q_PROPERTY(QString binPath READ binPath WRITE setBinPath NOTIFY binPathChanged)
  Q_PROPERTY(QStringList tags READ tags NOTIFY tagsChanged)
  Q_PROPERTY(QVariantList todos READ todos NOTIFY todosChanged)

public:
  explicit Tasks(QObject *parent = nullptr);

  QString binPath() const;
  void setBinPath(const QString &binPath);

  QStringList tags() const;
  QVariantList todos() const;

  Q_INVOKABLE void fetchTags();
  Q_INVOKABLE void fetchTodos();
  Q_INVOKABLE void saveTodo(const QString &description,
                            const QStringList &tags);
  Q_INVOKABLE void appendSessionLog(const QString &uuid, int focusMinutes,
                                    int breakMinutes,
                                    const QVariantList &events);
  Q_INVOKABLE void setTodoStatus(int index, const QString &marker);
  Q_INVOKABLE void annotateTodo(int index, const QString &note);

signals:
  void binPathChanged();
  void tagsChanged();
  void todosChanged();
  void saved();
  void saveFailed(const QString &error);

private:
  QProcess *startTask(const QStringList &arguments);
  void runMutation(const QStringList &arguments, const QString &label);
  QString uuidAt(int index) const;
  static QString normalizeTag(const QString &tag);
  static QString markerFromTask(const QVariantMap &task);
  static QVariantList parseTodos(const QByteArray &data);
  static QStringList parseTags(const QByteArray &data);

  QString m_binPath = QStringLiteral(
      "/home/matheus/Documents/personal-org-mode/Personal/Journal/todos/taskw");
  QStringList m_tags;
  QVariantList m_todos;
};
