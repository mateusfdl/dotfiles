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

QColor Colors::applyAlpha(const QColor &color, qreal alpha) {
  alpha = std::clamp(alpha, 0.0, 1.0);
  return QColor::fromRgbF(color.redF(), color.greenF(), color.blueF(), alpha);
}

QColor Colors::colorWithHueOf(const QColor &color1, const QColor &color2) {
  float h2, s1, v1, a1;
  color2.getHsvF(&h2, nullptr, nullptr, nullptr);
  color1.getHsvF(nullptr, &s1, &v1, &a1);
  return QColor::fromHsvF(h2, s1, v1, a1);
}

QColor Colors::colorWithSaturationOf(const QColor &color1,
                                     const QColor &color2) {
  float h1, v1, a1, s2;
  color1.getHsvF(&h1, nullptr, &v1, &a1);
  color2.getHsvF(nullptr, &s2, nullptr, nullptr);
  return QColor::fromHsvF(h1, s2, v1, a1);
}

QColor Colors::colorWithLightness(const QColor &color, qreal lightness) {
  lightness = std::clamp(lightness, 0.0, 1.0);
  float h, s, a;
  color.getHslF(&h, &s, nullptr, &a);
  return QColor::fromHslF(h, s, static_cast<float>(lightness), a);
}

QColor Colors::colorWithLightnessOf(const QColor &color1,
                                    const QColor &color2) {
  float l2;
  color2.getHslF(nullptr, nullptr, &l2, nullptr);
  return colorWithLightness(color1, static_cast<qreal>(l2));
}

QColor Colors::adaptToAccent(const QColor &color1, const QColor &color2) {
  float h2, s2, l1, a1;
  color2.getHslF(&h2, &s2, nullptr, nullptr);
  color1.getHslF(nullptr, nullptr, &l1, &a1);
  return QColor::fromHslF(h2, s2, l1, a1);
}

qreal Colors::luminance(const QColor &color) {
  return std::sqrt(0.299 * color.redF() * color.redF() +
                   0.587 * color.greenF() * color.greenF() +
                   0.114 * color.blueF() * color.blueF());
}

bool Colors::isDark(const QColor &color) { return luminance(color) < 0.5; }
