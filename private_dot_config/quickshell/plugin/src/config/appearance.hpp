#pragma once

#include <QColor>
#include <QFileSystemWatcher>
#include <QJsonObject>
#include <QObject>
#include <QString>
#include <QtQml/qqmlregistration.h>

struct Palette {
  QColor windowBackground;
  QColor primaryText;
  QColor layerBackground1;
  QColor layerBackground2;
  QColor layerBackground3;
  QColor surfaceText;
  QColor secondaryText;
  QColor borderPrimary;
  QColor shadowColor;
  QColor accentPrimary;
  QColor selectionBackground;
  QColor accentPrimaryText;
  QColor selectionText;
  QColor borderSecondary;
};

struct RoundingSpec {
  int unsharpen;
  int verysmall;
  int small;
  int normal;
  int large;
  int full;
};

struct SizeSpec {
  qreal barHeight;
  qreal notificationPopupWidth;
  qreal searchWidthCollapsed;
  qreal searchWidth;
  qreal hyprlandGapsOut;
  qreal barTopMargin;
  qreal elevationMargin;
  qreal fabShadowRadius;
  qreal fabHoveredShadowRadius;
};

struct TransparencySpec {
  qreal background;
  qreal content;
};

class M3Colors : public QObject {
  Q_OBJECT
  QML_ANONYMOUS
  Q_PROPERTY(bool darkmode READ darkmode NOTIFY changed)
  Q_PROPERTY(QColor m3windowBackground READ m3windowBackground NOTIFY changed)
  Q_PROPERTY(QColor m3primaryText READ m3primaryText NOTIFY changed)
  Q_PROPERTY(QColor m3layerBackground1 READ m3layerBackground1 NOTIFY changed)
  Q_PROPERTY(QColor m3layerBackground2 READ m3layerBackground2 NOTIFY changed)
  Q_PROPERTY(QColor m3layerBackground3 READ m3layerBackground3 NOTIFY changed)
  Q_PROPERTY(QColor m3surfaceText READ m3surfaceText NOTIFY changed)
  Q_PROPERTY(QColor m3secondaryText READ m3secondaryText NOTIFY changed)
  Q_PROPERTY(QColor m3borderPrimary READ m3borderPrimary NOTIFY changed)
  Q_PROPERTY(QColor m3shadowColor READ m3shadowColor NOTIFY changed)
  Q_PROPERTY(QColor m3accentPrimary READ m3accentPrimary NOTIFY changed)
  Q_PROPERTY(
      QColor m3selectionBackground READ m3selectionBackground NOTIFY changed)
  Q_PROPERTY(QColor m3selectionText READ m3selectionText NOTIFY changed)
  Q_PROPERTY(QColor m3borderSecondary READ m3borderSecondary NOTIFY changed)
  Q_PROPERTY(QColor m3outline READ m3outline NOTIFY changed)
  Q_PROPERTY(QColor m3onSurface READ m3onSurface NOTIFY changed)
  Q_PROPERTY(QColor m3onPrimary READ m3onPrimary NOTIFY changed)
  Q_PROPERTY(
      QColor m3onSecondaryContainer READ m3onSecondaryContainer NOTIFY changed)
  Q_PROPERTY(QColor m3primary READ m3primary NOTIFY changed)
  Q_PROPERTY(QColor colTooltip READ colTooltip NOTIFY changed)
  Q_PROPERTY(QColor colOnTooltip READ colOnTooltip NOTIFY changed)

public:
  explicit M3Colors(QObject *parent = nullptr);

  void apply(bool isDark, const Palette &palette);

  bool darkmode() const { return m_darkmode; }
  QColor m3windowBackground() const { return m_palette.windowBackground; }
  QColor m3primaryText() const { return m_palette.primaryText; }
  QColor m3layerBackground1() const { return m_palette.layerBackground1; }
  QColor m3layerBackground2() const { return m_palette.layerBackground2; }
  QColor m3layerBackground3() const { return m_palette.layerBackground3; }
  QColor m3surfaceText() const { return m_palette.surfaceText; }
  QColor m3secondaryText() const { return m_palette.secondaryText; }
  QColor m3borderPrimary() const { return m_palette.borderPrimary; }
  QColor m3shadowColor() const { return m_palette.shadowColor; }
  QColor m3accentPrimary() const { return m_palette.accentPrimary; }
  QColor m3selectionBackground() const { return m_palette.selectionBackground; }
  QColor m3selectionText() const { return m_palette.selectionText; }
  QColor m3borderSecondary() const { return m_palette.borderSecondary; }
  QColor m3outline() const { return m_outline; }
  QColor m3onSurface() const { return m_palette.primaryText; }
  QColor m3onPrimary() const { return m_palette.accentPrimaryText; }
  QColor m3onSecondaryContainer() const { return m_onSecondaryContainer; }
  QColor m3primary() const { return m_palette.accentPrimary; }
  QColor colTooltip() const { return m_colTooltip; }
  QColor colOnTooltip() const { return m_colOnTooltip; }

signals:
  void changed();

private:
  bool m_darkmode = false;
  Palette m_palette;
  QColor m_outline;
  QColor m_onSecondaryContainer;
  QColor m_colTooltip;
  QColor m_colOnTooltip;
};

class AppearanceColors : public QObject {
  Q_OBJECT
  QML_ANONYMOUS
  Q_PROPERTY(QColor colBackground READ colBackground NOTIFY changed)
  Q_PROPERTY(qreal transparency READ transparency NOTIFY changed)
  Q_PROPERTY(qreal contentTransparency READ contentTransparency NOTIFY changed)
  Q_PROPERTY(QColor colLayer0 READ colLayer0 NOTIFY changed)
  Q_PROPERTY(QColor colLayer1 READ colLayer1 NOTIFY changed)
  Q_PROPERTY(QColor colOnLayer1 READ colOnLayer1 NOTIFY changed)
  Q_PROPERTY(QColor colLayer2 READ colLayer2 NOTIFY changed)
  Q_PROPERTY(QColor colOnLayer2 READ colOnLayer2 NOTIFY changed)
  Q_PROPERTY(QColor colLayer1Hover READ colLayer1Hover NOTIFY changed)
  Q_PROPERTY(QColor colLayer2Hover READ colLayer2Hover NOTIFY changed)
  Q_PROPERTY(QColor colLayer2Active READ colLayer2Active NOTIFY changed)
  Q_PROPERTY(QColor colPrimary READ colPrimary NOTIFY changed)
  Q_PROPERTY(QColor colShadow READ colShadow NOTIFY changed)
  Q_PROPERTY(
      QColor colSecondaryContainer READ colSecondaryContainer NOTIFY changed)
  Q_PROPERTY(QColor colSurfaceContainerHighest READ colSurfaceContainerHighest
                 NOTIFY changed)

public:
  explicit AppearanceColors(QObject *parent = nullptr);

  void apply(const Palette &palette, const TransparencySpec &transparency);

  QColor colBackground() const { return m_colBackground; }
  qreal transparency() const { return m_transparency.background; }
  qreal contentTransparency() const { return m_transparency.content; }
  QColor colLayer0() const { return m_colLayer0; }
  QColor colLayer1() const { return m_colLayer1; }
  QColor colOnLayer1() const { return m_colOnLayer1; }
  QColor colLayer2() const { return m_colLayer2; }
  QColor colOnLayer2() const { return m_colOnLayer2; }
  QColor colLayer1Hover() const { return m_colLayer1Hover; }
  QColor colLayer2Hover() const { return m_colLayer2Hover; }
  QColor colLayer2Active() const { return m_colLayer2Active; }
  QColor colPrimary() const { return m_colPrimary; }
  QColor colShadow() const { return m_colShadow; }
  QColor colSecondaryContainer() const { return m_colSecondaryContainer; }
  QColor colSurfaceContainerHighest() const {
    return m_colSurfaceContainerHighest;
  }

signals:
  void changed();

private:
  TransparencySpec m_transparency = {0.0, 0.0};
  QColor m_colBackground;
  QColor m_colLayer0;
  QColor m_colLayer1;
  QColor m_colOnLayer1;
  QColor m_colLayer2;
  QColor m_colOnLayer2;
  QColor m_colLayer1Hover;
  QColor m_colLayer2Hover;
  QColor m_colLayer2Active;
  QColor m_colPrimary;
  QColor m_colShadow;
  QColor m_colSecondaryContainer;
  QColor m_colSurfaceContainerHighest;
};

class Rounding : public QObject {
  Q_OBJECT
  QML_ANONYMOUS
  Q_PROPERTY(int unsharpen READ unsharpen NOTIFY changed)
  Q_PROPERTY(int verysmall READ verysmall NOTIFY changed)
  Q_PROPERTY(int small READ small NOTIFY changed)
  Q_PROPERTY(int normal READ normal NOTIFY changed)
  Q_PROPERTY(int large READ large NOTIFY changed)
  Q_PROPERTY(int full READ full NOTIFY changed)

public:
  explicit Rounding(QObject *parent = nullptr);

  void apply(const RoundingSpec &spec);

  int unsharpen() const { return m_spec.unsharpen; }
  int verysmall() const { return m_spec.verysmall; }
  int small() const { return m_spec.small; }
  int normal() const { return m_spec.normal; }
  int large() const { return m_spec.large; }
  int full() const { return m_spec.full; }

signals:
  void changed();

private:
  RoundingSpec m_spec = {};
};

class Sizes : public QObject {
  Q_OBJECT
  QML_ANONYMOUS
  Q_PROPERTY(qreal barHeight READ barHeight NOTIFY changed)
  Q_PROPERTY(
      qreal notificationPopupWidth READ notificationPopupWidth NOTIFY changed)
  Q_PROPERTY(
      qreal searchWidthCollapsed READ searchWidthCollapsed NOTIFY changed)
  Q_PROPERTY(qreal searchWidth READ searchWidth NOTIFY changed)
  Q_PROPERTY(qreal hyprlandGapsOut READ hyprlandGapsOut NOTIFY changed)
  Q_PROPERTY(qreal barTopMargin READ barTopMargin NOTIFY changed)
  Q_PROPERTY(qreal elevationMargin READ elevationMargin NOTIFY changed)
  Q_PROPERTY(qreal fabShadowRadius READ fabShadowRadius NOTIFY changed)
  Q_PROPERTY(
      qreal fabHoveredShadowRadius READ fabHoveredShadowRadius NOTIFY changed)

public:
  explicit Sizes(QObject *parent = nullptr);

  void apply(const SizeSpec &spec);

  qreal barHeight() const { return m_spec.barHeight; }
  qreal notificationPopupWidth() const { return m_spec.notificationPopupWidth; }
  qreal searchWidthCollapsed() const { return m_spec.searchWidthCollapsed; }
  qreal searchWidth() const { return m_spec.searchWidth; }
  qreal hyprlandGapsOut() const { return m_spec.hyprlandGapsOut; }
  qreal barTopMargin() const { return m_spec.barTopMargin; }
  qreal elevationMargin() const { return m_spec.elevationMargin; }
  qreal fabShadowRadius() const { return m_spec.fabShadowRadius; }
  qreal fabHoveredShadowRadius() const { return m_spec.fabHoveredShadowRadius; }

signals:
  void changed();

private:
  SizeSpec m_spec = {};
};

class Appearance : public QObject {
  Q_OBJECT
  QML_ELEMENT
  QML_SINGLETON
  Q_PROPERTY(QString currentThemeMode READ currentThemeMode WRITE
                 setCurrentThemeMode NOTIFY currentThemeModeChanged)
  Q_PROPERTY(M3Colors *m3colors READ m3colors CONSTANT)
  Q_PROPERTY(AppearanceColors *colors READ colors CONSTANT)
  Q_PROPERTY(Rounding *rounding READ rounding CONSTANT)
  Q_PROPERTY(Sizes *sizes READ sizes CONSTANT)

public:
  explicit Appearance(QObject *parent = nullptr);

  QString currentThemeMode() const { return m_currentThemeMode; }
  void setCurrentThemeMode(const QString &mode);

  M3Colors *m3colors() const { return m_m3colors; }
  AppearanceColors *colors() const { return m_colors; }
  Rounding *rounding() const { return m_rounding; }
  Sizes *sizes() const { return m_sizes; }

signals:
  void currentThemeModeChanged();

private:
  void reloadFile();
  void recompute();

  QString m_themePath;
  QString m_currentThemeMode = QStringLiteral("dark");
  QJsonObject m_themeData;
  QFileSystemWatcher m_watcher;

  M3Colors *m_m3colors;
  AppearanceColors *m_colors;
  Rounding *m_rounding;
  Sizes *m_sizes;
};
