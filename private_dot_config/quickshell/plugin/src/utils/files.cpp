#include "files.hpp"

#include <QFileInfo>
#include <QUrl>

Files::Files(QObject *parent) : QObject(parent) {}

QString Files::trimFileProtocol(const QString &str) {
  QUrl url(str);
  if (url.isLocalFile()) {
    return url.toLocalFile();
  }
  return str;
}

