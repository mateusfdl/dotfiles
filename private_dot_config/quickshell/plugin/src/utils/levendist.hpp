#pragma once

#include <QObject>
#include <QString>
#include <QStringView>
#include <QtQml/qqmlregistration.h>

class Levendist : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit Levendist(QObject* parent = nullptr);

    Q_INVOKABLE static qreal computeScore(const QString& s1, const QString& s2);
    Q_INVOKABLE static qreal computeTextMatchScore(const QString& s1, const QString& s2);

private:
    static int levenshteinDistance(QStringView s1, QStringView s2);
    static qreal partialRatio(QStringView shortS, QStringView longS);
};
