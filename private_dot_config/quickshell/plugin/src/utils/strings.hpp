#pragma once

#include <QObject>
#include <QString>
#include <QtQml/qqmlregistration.h>

class Strings : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit Strings(QObject* parent = nullptr);

    Q_INVOKABLE static QString shellSingleQuoteEscape(const QString& str);
    Q_INVOKABLE static QString escapeHtml(const QString& str);
    Q_INVOKABLE static QString getDomain(const QString& url);
};
