#pragma once

#include <QObject>
#include <QString>
#include <QtQml/qqmlregistration.h>

class Files : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit Files(QObject* parent = nullptr);

    Q_INVOKABLE static QString trimFileProtocol(const QString& str);
    Q_INVOKABLE static QString parentDirectory(const QString& str);
};
