#pragma once

#include <QDateTime>
#include <QHash>
#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariantList>
#include <QtQml/qqmlregistration.h>

#include <functional>
#include <memory>

class TasksTest;

class Tasks : public QObject {
  Q_OBJECT
  QML_ELEMENT
  QML_SINGLETON
  Q_PROPERTY(QStringList tags READ tags NOTIFY tagsChanged)
  Q_PROPERTY(QVariantList todos READ todos NOTIFY todosChanged)
  Q_PROPERTY(qint64 projectId READ projectId WRITE setProjectId NOTIFY
                 projectIdChanged)

public:
  explicit Tasks(QObject *parent = nullptr);

  QStringList tags() const;
  QVariantList todos() const;
  qint64 projectId() const;
  void setProjectId(qint64 projectId);

  Q_INVOKABLE void fetchTags();
  Q_INVOKABLE void fetchTodos();
  Q_INVOKABLE void saveTodo(const QString &description,
                            const QStringList &tags);
  Q_INVOKABLE bool appendSessionLog(const QString &noteId, int focusMinutes,
                                    int breakMinutes,
                                    const QVariantList &events);
  Q_INVOKABLE bool setTodoStatus(int index, const QString &marker);
  Q_INVOKABLE bool annotateTodo(int index, const QString &note);

signals:
  void tagsChanged();
  void todosChanged();
  void projectIdChanged();
  void saved();
  void saveFailed(const QString &error);
  void operationFailed(const QString &error);

private:
  struct ItemPage {
    bool valid = false;
    QVariantList items;
    int page = 0;
    int totalPages = 0;
  };

  struct LabelPage {
    bool valid = false;
    QHash<QString, qint64> labels;
    int page = 0;
    int totalPages = 0;
  };

  struct SaveOperation {
    QString taskId;
    QStringList tags;
    QHash<QString, qint64> labels;
    qsizetype index = 0;
  };

  using CliCallback =
      std::function<void(bool, const QByteArray &, const QString &)>;
  using LabelsCallback = std::function<void(
      bool, const QHash<QString, qint64> &, const QString &)>;

  void runCli(const QStringList &arguments, CliCallback callback);
  void fetchTodoPage(int page, QVariantList accumulated, quint64 generation);
  void fetchLabelPage(int page, QHash<QString, qint64> accumulated,
                      LabelsCallback callback);
  void startCommentFetches(quint64 generation);
  void fetchCommentPage(const QString &taskId, int page,
                        QVariantList accumulated, quint64 generation);
  void completeCommentFetch(quint64 generation);
  void continueSave(const std::shared_ptr<SaveOperation> &operation);
  void attachSaveLabel(const std::shared_ptr<SaveOperation> &operation,
                       qint64 labelId);
  void refreshAfterMutation();

  static ItemPage parseTodoPage(const QByteArray &data);
  static LabelPage parseLabelPage(const QByteArray &data);
  static ItemPage parseCommentPage(const QByteArray &data);
  static QString markerFromTask(
      const QVariantMap &task,
      const QDateTime &now = QDateTime::currentDateTime());
  static QString cleanLabel(const QString &label);
  static QString taskIdAt(const QVariantList &todos, int index);
  static QString dueDateFor(const QDate &date);
  static QString errorMessage(const QByteArray &stderrData,
                              const QString &fallback);

  QStringList m_tags;
  QVariantList m_todos;
  QHash<QString, qint64> m_labelIds;
  QStringList m_pendingCommentIds;
  qint64 m_projectId = 1;
  quint64 m_todoGeneration = 0;
  int m_activeCommentFetches = 0;

  static constexpr int COMMENT_CONCURRENCY = 4;
  static constexpr int CLI_TIMEOUT_MS = 15000;

  friend class TasksTest;
};
