#pragma once

#include <QColor>
#include <QJsonObject>
#include <QString>
#include <QStringList>

class JsonValidator {
public:
  explicit JsonValidator(QString context);

  QColor requireColor(const QJsonObject &object, const QString &key);
  qreal requireReal(const QJsonObject &object, const QString &key);
  int requireInt(const QJsonObject &object, const QString &key);
  QString requireString(const QJsonObject &object, const QString &key);

  bool valid() const;
  const QStringList &errors() const;

private:
  void fail(const QString &key, const QString &reason);

  QString m_context;
  QStringList m_errors;
};
