#include "colors.hpp"

#include <algorithm>
#include <cmath>

Colors::Colors(QObject *parent) : QObject(parent) {}

QColor Colors::mix(const QColor &color1, const QColor &color2, qreal ratio) {
  ratio = std::clamp(ratio, 0.0, 1.0);
  const qreal inv = 1.0 - ratio;
  return QColor::fromRgbF(ratio * color1.redF() + inv * color2.redF(),
                          ratio * color1.greenF() + inv * color2.greenF(),
                          ratio * color1.blueF() + inv * color2.blueF(),
                          ratio * color1.alphaF() + inv * color2.alphaF());
}

QColor Colors::transparentize(const QColor &color, qreal amount) {
  amount = std::clamp(amount, 0.0, 1.0);
  return QColor::fromRgbF(color.redF(), color.greenF(), color.blueF(),
                          color.alphaF() * (1.0 - amount));
}
