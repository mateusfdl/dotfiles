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
    explicit HyprlandWorkspace(QObject* parent = nullptr);

    /// Returns the next workspace ID in sorted order, or -1 if at the end.
    Q_INVOKABLE static int navigateForward(const QList<int>& workspaceIds, int currentId);

    /// Returns the previous workspace ID in sorted order, or -1 if at the start.
    Q_INVOKABLE static int navigateBackward(const QList<int>& workspaceIds, int currentId);

    /// Renames all workspaces with id >= currentId+1 upward by 1 (reverse order),
    /// creating an empty slot at currentId+1. Returns the new slot ID, or -1 on failure.
    Q_INVOKABLE static int insertWorkspaceAfter(const QList<int>& workspaceIds, int currentId);

private:
    /// Send a single dispatch command to Hyprland via its UNIX domain socket.
    static bool hyprlandDispatch(const QString& command);

    /// Resolve the Hyprland command socket path from the environment.
    static QString hyprlandSocketPath();
};
