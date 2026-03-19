#include "strings.hpp"

#include <QRegularExpression>

Strings::Strings(QObject *parent) : QObject(parent) {}

QString Strings::shellSingleQuoteEscape(const QString &str) {
  QString result = str;
  result.replace(QStringLiteral("'"), QStringLiteral("'\\''"));
  return result;
}

QString Strings::escapeHtml(const QString &str) {
  QString result;
  result.reserve(str.size() + str.size() / 8);

  for (QChar ch : str) {
    switch (ch.unicode()) {
    case u'&':
      result += QStringLiteral("&amp;");
      break;
    case u'<':
      result += QStringLiteral("&lt;");
      break;
    case u'>':
      result += QStringLiteral("&gt;");
      break;
    case u'"':
      result += QStringLiteral("&quot;");
      break;
    case u'\'':
      result += QStringLiteral("&#39;");
      break;
    default:
      result += ch;
      break;
    }
  }

  return result;
}

QString Strings::getDomain(const QString &url) {
  static const QRegularExpression re(
      QStringLiteral("^(?:https?://)?(?:www\\.)?([^/]+)"));
  const auto match = re.match(url);
  return match.hasMatch() ? match.captured(1) : QString();
}
