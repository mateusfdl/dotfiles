#pragma once

#include <QColor>
#include <QObject>
#include <QtQml/qqmlregistration.h>

class Colors : public QObject {
  Q_OBJECT
  QML_ELEMENT
  QML_SINGLETON

public:
  explicit Colors(QObject *parent = nullptr);

  Q_INVOKABLE static QColor mix(const QColor &color1, const QColor &color2,
                                qreal ratio = 0.5);
  Q_INVOKABLE static QColor transparentize(const QColor &color,
                                           qreal amount = 1.0);
};
