#include "jsonvalidator.hpp"

#include <QJsonValue>
#include <utility>

JsonValidator::JsonValidator(QString context) : m_context(std::move(context)) {}

void JsonValidator::fail(const QString &key, const QString &reason) {
  m_errors.append(
      QStringLiteral("%1: key '%2' %3").arg(m_context, key, reason));
}

QColor JsonValidator::requireColor(const QJsonObject &object,
                                   const QString &key) {
  if (!object.contains(key)) {
    fail(key, QStringLiteral("is missing"));
    return {};
  }
  const auto value = object.value(key);
  if (!value.isString()) {
    fail(key, QStringLiteral("must be a color string"));
    return {};
  }
  QColor color(value.toString());
  if (!color.isValid()) {
    fail(key, QStringLiteral("is not a valid color: '%1'").arg(value.toString()));
    return {};
  }
  return color;
}

qreal JsonValidator::requireReal(const QJsonObject &object, const QString &key) {
  if (!object.contains(key)) {
    fail(key, QStringLiteral("is missing"));
    return 0.0;
  }
  const auto value = object.value(key);
  if (!value.isDouble()) {
    fail(key, QStringLiteral("must be a number"));
    return 0.0;
  }
  return value.toDouble();
}

int JsonValidator::requireInt(const QJsonObject &object, const QString &key) {
  if (!object.contains(key)) {
    fail(key, QStringLiteral("is missing"));
    return 0;
  }
  const auto value = object.value(key);
  if (!value.isDouble()) {
    fail(key, QStringLiteral("must be a number"));
    return 0;
  }
  return value.toInt();
}

QString JsonValidator::requireString(const QJsonObject &object,
                                     const QString &key) {
  if (!object.contains(key)) {
    fail(key, QStringLiteral("is missing"));
    return {};
  }
  const auto value = object.value(key);
  if (!value.isString()) {
    fail(key, QStringLiteral("must be a string"));
    return {};
  }
  return value.toString();
}

bool JsonValidator::valid() const { return m_errors.isEmpty(); }

const QStringList &JsonValidator::errors() const { return m_errors; }
