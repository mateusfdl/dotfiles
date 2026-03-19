#pragma once

#include <QList>
#include <QObject>
#include <QString>
#include <QtQml/qqmlregistration.h>

class HyprlandWorkspace : public QObject {
  Q_OBJECT
  QML_ELEMENT
  QML_SINGLETON

public:
  explicit HyprlandWorkspace(QObject *parent = nullptr);

  Q_INVOKABLE static int navigateForward(const QList<int> &workspaceIds,
                                         int currentId);
  Q_INVOKABLE static int navigateBackward(const QList<int> &workspaceIds,
                                          int currentId);
  Q_INVOKABLE static int insertWorkspaceAfter(const QList<int> &workspaceIds,
                                              int currentId);

private:
  static bool hyprlandDispatch(const QString &command);
  static QString hyprlandSocketPath();
};
