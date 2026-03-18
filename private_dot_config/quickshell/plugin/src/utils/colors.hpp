#pragma once

#include <QColor>
#include <QObject>
#include <QtQml/qqmlregistration.h>

class Colors : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit Colors(QObject* parent = nullptr);

    Q_INVOKABLE static QColor mix(const QColor& color1, const QColor& color2, qreal ratio = 0.5);
    Q_INVOKABLE static QColor transparentize(const QColor& color, qreal amount = 1.0);
    Q_INVOKABLE static QColor applyAlpha(const QColor& color, qreal alpha);
    Q_INVOKABLE static QColor colorWithHueOf(const QColor& color1, const QColor& color2);
    Q_INVOKABLE static QColor colorWithSaturationOf(const QColor& color1, const QColor& color2);
    Q_INVOKABLE static QColor colorWithLightness(const QColor& color, qreal lightness);
    Q_INVOKABLE static QColor colorWithLightnessOf(const QColor& color1, const QColor& color2);
    Q_INVOKABLE static QColor adaptToAccent(const QColor& color1, const QColor& color2);
    Q_INVOKABLE static qreal luminance(const QColor& color);
    Q_INVOKABLE static bool isDark(const QColor& color);
};
