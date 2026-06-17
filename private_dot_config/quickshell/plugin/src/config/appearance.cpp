#include "appearance.hpp"

#include "colors.hpp"
#include "jsonvalidator.hpp"

#include <QDebug>
#include <QFile>
#include <QJsonDocument>
#include <QJsonParseError>
#include <QStandardPaths>

namespace {

Palette parsePalette(const QJsonObject &source, JsonValidator &validator) {
  Palette palette;
  palette.windowBackground =
      validator.requireColor(source, QStringLiteral("windowBackground"));
  palette.primaryText =
      validator.requireColor(source, QStringLiteral("primaryText"));
  palette.layerBackground1 =
      validator.requireColor(source, QStringLiteral("layerBackground1"));
  palette.layerBackground2 =
      validator.requireColor(source, QStringLiteral("layerBackground2"));
  palette.layerBackground3 =
      validator.requireColor(source, QStringLiteral("layerBackground3"));
  palette.surfaceText =
      validator.requireColor(source, QStringLiteral("surfaceText"));
  palette.secondaryText =
      validator.requireColor(source, QStringLiteral("secondaryText"));
  palette.borderPrimary =
      validator.requireColor(source, QStringLiteral("borderPrimary"));
  palette.shadowColor =
      validator.requireColor(source, QStringLiteral("shadowColor"));
  palette.accentPrimary =
      validator.requireColor(source, QStringLiteral("accentPrimary"));
  palette.selectionBackground =
      validator.requireColor(source, QStringLiteral("selectionBackground"));
  palette.accentPrimaryText =
      validator.requireColor(source, QStringLiteral("accentPrimaryText"));
  palette.selectionText =
      validator.requireColor(source, QStringLiteral("selectionText"));
  palette.borderSecondary =
      validator.requireColor(source, QStringLiteral("borderSecondary"));
  return palette;
}

RoundingSpec parseRounding(const QJsonObject &source,
                           JsonValidator &validator) {
  return {
      validator.requireInt(source, QStringLiteral("unsharpen")),
      validator.requireInt(source, QStringLiteral("verysmall")),
      validator.requireInt(source, QStringLiteral("small")),
      validator.requireInt(source, QStringLiteral("normal")),
      validator.requireInt(source, QStringLiteral("large")),
      validator.requireInt(source, QStringLiteral("full")),
  };
}

SizeSpec parseSizes(const QJsonObject &source, JsonValidator &validator) {
  return {
      validator.requireReal(source, QStringLiteral("barHeight")),
      validator.requireReal(source, QStringLiteral("notificationPopupWidth")),
      validator.requireReal(source, QStringLiteral("searchWidthCollapsed")),
      validator.requireReal(source, QStringLiteral("searchWidth")),
      validator.requireReal(source, QStringLiteral("hyprlandGapsOut")),
      validator.requireReal(source, QStringLiteral("barTopMargin")),
      validator.requireReal(source, QStringLiteral("elevationMargin")),
      validator.requireReal(source, QStringLiteral("fabShadowRadius")),
      validator.requireReal(source, QStringLiteral("fabHoveredShadowRadius")),
  };
}

TransparencySpec parseTransparency(const QJsonObject &source,
                                   JsonValidator &validator) {
  return {
      validator.requireReal(source, QStringLiteral("background")),
      validator.requireReal(source, QStringLiteral("content")),
  };
}

} // namespace

M3Colors::M3Colors(QObject *parent) : QObject(parent) {}

void M3Colors::apply(bool isDark, const Palette &palette) {
  m_darkmode = isDark;
  m_palette = palette;
  m_outline = Colors::mix(palette.borderPrimary, palette.windowBackground, 0.5);
  m_onSecondaryContainer =
      Colors::mix(palette.accentPrimary, palette.windowBackground, 0.3);
  m_colTooltip = isDark ? QColor(QStringLiteral("#1f2335"))
                        : QColor(QStringLiteral("#F4F0D9"));
  m_colOnTooltip = isDark ? QColor(QStringLiteral("#c0caf5"))
                          : QColor(QStringLiteral("#5C6A72"));
  emit changed();
}

AppearanceColors::AppearanceColors(QObject *parent) : QObject(parent) {}

void AppearanceColors::apply(const Palette &palette,
                             const TransparencySpec &transparency) {
  m_transparency = transparency;
  m_colBackground = palette.windowBackground;
  m_colLayer0 =
      Colors::transparentize(palette.windowBackground, transparency.background);
  m_colLayer1 =
      Colors::mix(palette.layerBackground1, palette.windowBackground, 1.0);
  m_colOnLayer1 = palette.secondaryText;
  m_colLayer2 = Colors::transparentize(
      Colors::mix(palette.layerBackground2, palette.layerBackground3, 0.55),
      transparency.content);
  m_colOnLayer2 = palette.surfaceText;
  m_colLayer1Hover = Colors::transparentize(
      Colors::mix(m_colLayer1, m_colOnLayer1, 0.92), transparency.content);
  m_colLayer2Hover = Colors::transparentize(
      Colors::mix(m_colLayer2, m_colOnLayer2, 0.90), transparency.content);
  m_colLayer2Active = Colors::transparentize(
      Colors::mix(m_colLayer2, m_colOnLayer2, 0.80), transparency.content);
  m_colPrimary = palette.accentPrimary;
  m_colShadow = Colors::transparentize(palette.shadowColor, 0.7);
  m_colSecondaryContainer = Colors::transparentize(
      Colors::mix(palette.layerBackground2, palette.accentPrimary, 0.85), 0.5);
  m_colSurfaceContainerHighest = Colors::transparentize(
      Colors::mix(palette.layerBackground3, palette.windowBackground, 0.5),
      0.3);
  emit changed();
}

Rounding::Rounding(QObject *parent) : QObject(parent) {}

void Rounding::apply(const RoundingSpec &spec) {
  m_spec = spec;
  emit changed();
}

Sizes::Sizes(QObject *parent) : QObject(parent) {}

void Sizes::apply(const SizeSpec &spec) {
  m_spec = spec;
  emit changed();
}

Appearance::Appearance(QObject *parent)
    : QObject(parent), m_m3colors(new M3Colors(this)),
      m_colors(new AppearanceColors(this)), m_rounding(new Rounding(this)),
      m_sizes(new Sizes(this)) {
  m_themePath =
      QStandardPaths::writableLocation(QStandardPaths::ConfigLocation) +
      QStringLiteral("/quickshell/config/theme.json");
  connect(&m_watcher, &QFileSystemWatcher::fileChanged, this,
          [this](const QString &) { reloadFile(); });
  reloadFile();
}

void Appearance::setCurrentThemeMode(const QString &mode) {
  if (mode == m_currentThemeMode)
    return;
  m_currentThemeMode = mode;
  emit currentThemeModeChanged();
  recompute();
}

void Appearance::reloadFile() {
  QFile file(m_themePath);
  if (!file.open(QIODevice::ReadOnly)) {
    qCritical().noquote() << QStringLiteral(
                                 "[Appearance] cannot open theme file: %1")
                                 .arg(m_themePath);
    return;
  }
  const auto data = file.readAll();
  file.close();

  if (!m_watcher.files().contains(m_themePath))
    m_watcher.addPath(m_themePath);

  QJsonParseError parseError;
  const auto document = QJsonDocument::fromJson(data, &parseError);
  if (parseError.error != QJsonParseError::NoError || !document.isObject()) {
    qCritical().noquote() << QStringLiteral(
                                 "[Appearance] failed to parse theme.json: %1")
                                 .arg(parseError.errorString());
    return;
  }

  m_themeData = document.object();
  recompute();
}

void Appearance::recompute() {
  if (m_themeData.isEmpty())
    return;

  const bool isDark = m_currentThemeMode == QStringLiteral("dark");

  JsonValidator colorValidator(
      QStringLiteral("colors[%1]").arg(m_currentThemeMode));
  JsonValidator roundingValidator(QStringLiteral("rounding"));
  JsonValidator sizesValidator(QStringLiteral("sizes"));
  JsonValidator transparencyValidator(QStringLiteral("transparency"));

  const Palette palette = parsePalette(
      m_themeData.value(m_currentThemeMode).toObject(), colorValidator);
  const RoundingSpec rounding =
      parseRounding(m_themeData.value(QStringLiteral("rounding")).toObject(),
                    roundingValidator);
  const SizeSpec sizes = parseSizes(
      m_themeData.value(QStringLiteral("sizes")).toObject(), sizesValidator);
  const TransparencySpec transparency = parseTransparency(
      m_themeData.value(QStringLiteral("transparency")).toObject(),
      transparencyValidator);

  QStringList errors;
  errors << colorValidator.errors() << roundingValidator.errors()
         << sizesValidator.errors() << transparencyValidator.errors();
  if (!errors.isEmpty()) {
    qCritical().noquote()
        << QStringLiteral("[Appearance] invalid theme '%1'; refusing to apply:")
               .arg(m_currentThemeMode);
    for (const auto &error : errors)
      qCritical().noquote() << QStringLiteral("  - %1").arg(error);
    return;
  }

  m_m3colors->apply(isDark, palette);
  m_colors->apply(palette, transparency);
  m_rounding->apply(rounding);
  m_sizes->apply(sizes);
}
