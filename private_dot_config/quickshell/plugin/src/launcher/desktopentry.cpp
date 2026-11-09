#include "desktopentry.hpp"

#include <algorithm>
#include <cstring>
#include <string>

namespace {

constexpr std::string_view UTF8_BOM = "\xEF\xBB\xBF";
constexpr std::string_view DESKTOP_ENTRY_GROUP = "[Desktop Entry]";

bool isBlank(char c) { return c == ' ' || c == '\t'; }

std::string_view trimLeft(std::string_view text) {
  while (!text.empty() && isBlank(text.front()))
    text.remove_prefix(1);
  return text;
}

std::string_view trimRight(std::string_view text) {
  while (!text.empty() && isBlank(text.back()))
    text.remove_suffix(1);
  return text;
}

std::string_view takeLine(std::string_view &rest) {
  const auto *newline =
      static_cast<const char *>(std::memchr(rest.data(), '\n', rest.size()));
  const auto length = newline == nullptr
                          ? rest.size()
                          : static_cast<std::size_t>(newline - rest.data());
  auto line = rest.substr(0, length);
  rest.remove_prefix(newline == nullptr ? length : length + 1);
  if (!line.empty() && line.back() == '\r')
    line.remove_suffix(1);
  return line;
}

char decodedEscape(char escaped) {
  switch (escaped) {
  case 's':
    return ' ';
  case 'n':
    return '\n';
  case 't':
    return '\t';
  case 'r':
    return '\r';
  case '\\':
    return '\\';
  default:
    return '\0';
  }
}

QString toQString(const std::string &utf8) {
  return QString::fromUtf8(utf8.data(), static_cast<qsizetype>(utf8.size()));
}

QString decodeString(std::string_view raw) {
  std::string decoded;
  decoded.reserve(raw.size());
  for (std::size_t i = 0; i < raw.size(); ++i) {
    const char next = i + 1 < raw.size() ? raw[i + 1] : '\0';
    const char escape = raw[i] == '\\' ? decodedEscape(next) : '\0';
    if (escape != '\0') {
      decoded += escape;
      ++i;
      continue;
    }
    decoded += raw[i];
  }
  return toQString(decoded);
}

QStringList decodeList(std::string_view raw) {
  QStringList items;
  std::string item;
  const auto flush = [&] {
    if (!item.empty())
      items.append(toQString(item));
    item.clear();
  };
  for (std::size_t i = 0; i < raw.size(); ++i) {
    const char next = i + 1 < raw.size() ? raw[i + 1] : '\0';
    if (raw[i] == '\\' && next == ';') {
      item += ';';
      ++i;
      continue;
    }
    const char escape = raw[i] == '\\' ? decodedEscape(next) : '\0';
    if (escape != '\0') {
      item += escape;
      ++i;
      continue;
    }
    if (raw[i] == ';') {
      flush();
      continue;
    }
    item += raw[i];
  }
  flush();
  return items;
}

bool decodeBoolean(std::string_view raw) { return raw == "true" || raw == "1"; }

void assign(DesktopEntry &entry, std::string_view key, std::string_view value) {
  if (key == "Type")
    entry.type = decodeString(value);
  else if (key == "Name")
    entry.name = decodeString(value);
  else if (key == "Exec")
    entry.exec = decodeString(value);
  else if (key == "Icon")
    entry.icon = decodeString(value);
  else if (key == "Comment")
    entry.comment = decodeString(value);
  else if (key == "Path")
    entry.path = decodeString(value);
  else if (key == "Categories")
    entry.categories = decodeList(value);
  else if (key == "OnlyShowIn")
    entry.onlyShowIn = decodeList(value);
  else if (key == "NotShowIn")
    entry.notShowIn = decodeList(value);
  else if (key == "Hidden")
    entry.hidden = decodeBoolean(value);
  else if (key == "NoDisplay")
    entry.noDisplay = decodeBoolean(value);
  else if (key == "Terminal")
    entry.terminal = decodeBoolean(value);
}

bool listsAny(const QStringList &desktops, const QStringList &currentDesktops) {
  return std::ranges::any_of(currentDesktops, [&](const QString &desktop) {
    return desktops.contains(desktop, Qt::CaseInsensitive);
  });
}

} // namespace

DesktopEntry DesktopEntry::parse(std::string_view bytes) {
  if (bytes.starts_with(UTF8_BOM))
    bytes.remove_prefix(UTF8_BOM.size());

  DesktopEntry entry;
  bool inDesktopEntryGroup = false;
  while (!bytes.empty()) {
    const auto line = trimLeft(takeLine(bytes));
    if (line.empty() || line.front() == '#')
      continue;
    if (line.front() == '[') {
      if (inDesktopEntryGroup)
        break;
      inDesktopEntryGroup = trimRight(line) == DESKTOP_ENTRY_GROUP;
      continue;
    }
    if (!inDesktopEntryGroup)
      continue;
    const auto equals = line.find('=');
    if (equals == std::string_view::npos)
      continue;
    const auto key = trimRight(line.substr(0, equals));
    if (key.find('[') != std::string_view::npos)
      continue;
    assign(entry, key, trimRight(trimLeft(line.substr(equals + 1))));
  }
  return entry;
}

bool DesktopEntry::isShownIn(const QStringList &currentDesktops) const {
  if (type != QStringLiteral("Application") || hidden || noDisplay ||
      name.isEmpty() || exec.isEmpty())
    return false;
  if (!onlyShowIn.isEmpty() && !listsAny(onlyShowIn, currentDesktops))
    return false;
  return !listsAny(notShowIn, currentDesktops);
}
