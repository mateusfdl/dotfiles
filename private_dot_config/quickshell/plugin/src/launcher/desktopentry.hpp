#pragma once

#include <QString>
#include <QStringList>

#include <string_view>

struct DesktopEntry {
  QString type;
  QString name;
  QString exec;
  QString icon;
  QString comment;
  QString path;
  QStringList categories;
  QStringList onlyShowIn;
  QStringList notShowIn;
  bool hidden{false};
  bool noDisplay{false};
  bool terminal{false};

  [[nodiscard]] static DesktopEntry parse(std::string_view bytes);
  [[nodiscard]] bool isShownIn(const QStringList &currentDesktops) const;

  friend bool operator==(const DesktopEntry &, const DesktopEntry &) = default;
};
