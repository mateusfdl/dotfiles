#include "tasks.hpp"

#include <QDateTime>
#include <QtTest/QTest>

class TasksTest : public QObject {
  Q_OBJECT

private slots:
  void parsesTaskPage();
  void rejectsMalformedTaskPage();
  void mapsNativeStatusFields();
  void parsesLabels();
  void parsesComments();
  void buildsRfc3339DueDateWithoutSystemZoneId();
};

void TasksTest::parsesTaskPage() {
  const auto page = Tasks::parseTodoPage(R"({
    "data": [{
      "id": 42,
      "title": "Ship Vikunja adapter",
      "done": false,
      "due_date": "2026-07-24T20:00:00Z",
      "priority": 0,
      "percent_done": 0,
      "labels": [{"id": 7, "title": "quickshell"}]
    }],
    "page": 1,
    "total_pages": 2,
    "result_count": 1
  })");

  QCOMPARE(page.valid, true);
  QCOMPARE(page.page, 1);
  QCOMPARE(page.totalPages, 2);
  QCOMPARE(page.items.size(), 1);

  const auto todo = page.items.first().toMap();
  QCOMPARE(todo.value("uuid").toString(), QStringLiteral("42"));
  QCOMPARE(todo.value("noteId").toString(), QStringLiteral("42"));
  QCOMPARE(todo.value("description").toString(),
           QStringLiteral("Ship Vikunja adapter"));
  QCOMPARE(todo.value("tags").toStringList(),
           QStringList{QStringLiteral("quickshell")});
  QCOMPARE(todo.value("annotations").toList(), QVariantList{});
}

void TasksTest::rejectsMalformedTaskPage() {
  const auto page = Tasks::parseTodoPage(R"({"data": {}})");

  QCOMPARE(page.valid, false);
  QCOMPARE(page.items, QVariantList{});
}

void TasksTest::mapsNativeStatusFields() {
  const auto now = QDateTime::fromString(QStringLiteral("2026-07-23T12:00:00Z"),
                                         Qt::ISODate);
  QVariantMap task;

  task[QStringLiteral("done")] = true;
  QCOMPARE(Tasks::markerFromTask(task, now), QStringLiteral("x"));

  task = {{QStringLiteral("percent_done"), 0.5}};
  QCOMPARE(Tasks::markerFromTask(task, now), QStringLiteral("/"));

  task = {{QStringLiteral("priority"), 1}};
  QCOMPARE(Tasks::markerFromTask(task, now), QStringLiteral("?"));

  task = {{QStringLiteral("priority"), 5}};
  QCOMPARE(Tasks::markerFromTask(task, now), QStringLiteral("!"));

  task = {{QStringLiteral("due_date"),
           QStringLiteral("2026-07-24T12:00:00Z")}};
  QCOMPARE(Tasks::markerFromTask(task, now), QStringLiteral(">"));

  task.clear();
  QCOMPARE(Tasks::markerFromTask(task, now), QStringLiteral(" "));
}

void TasksTest::parsesLabels() {
  const auto page = Tasks::parseLabelPage(R"({
    "data": [
      {"id": 2, "title": "work"},
      {"id": 1, "title": "ação"}
    ],
    "page": 1,
    "total_pages": 1,
    "result_count": 2
  })");

  QCOMPARE(page.valid, true);
  QCOMPARE(page.labels.value(QStringLiteral("work")), 2);
  QCOMPARE(page.labels.value(QStringLiteral("ação")), 1);
}

void TasksTest::parsesComments() {
  const auto page = Tasks::parseCommentPage(R"({
    "data": [{
      "id": 9,
      "comment": "Investigated the reload",
      "created": "2026-07-23T12:30:00Z"
    }],
    "page": 1,
    "total_pages": 1,
    "result_count": 1
  })");

  QCOMPARE(page.valid, true);
  QCOMPARE(page.items.size(), 1);
  QCOMPARE(page.items.first().toMap(),
           QVariantMap({{QStringLiteral("description"),
                         QStringLiteral("Investigated the reload")},
                        {QStringLiteral("entry"),
                         QStringLiteral("2026-07-23T12:30:00Z")}}));
}

void TasksTest::buildsRfc3339DueDateWithoutSystemZoneId() {
  const auto due = Tasks::dueDateFor(QDate(2026, 7, 25));

  const auto parsed = QDateTime::fromString(due, Qt::ISODate);

  QCOMPARE(due.isEmpty(), false);
  QCOMPARE(due.startsWith(QStringLiteral("2026-07-25T23:59:59")), true);
  QCOMPARE(parsed.isValid(), true);
  QCOMPARE(parsed.timeSpec() == Qt::LocalTime, false);
}

QTEST_MAIN(TasksTest)

#include "tasks_test.moc"
