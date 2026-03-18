#pragma once

#include <QAbstractListModel>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLocalSocket>
#include <QObject>
#include <QRectF>
#include <QTimer>
#include <QVariant>
#include <QVector>
#include <QtQml/qqmlregistration.h>

class MissionControlModel : public QAbstractListModel {
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)
    Q_PROPERTY(bool ready READ isReady NOTIFY readyChanged)
    Q_PROPERTY(bool exposed READ isExposed NOTIFY exposedChanged)
    Q_PROPERTY(bool animating READ isAnimating NOTIFY animatingChanged)

public:
    enum WindowRoles {
        AddressRole = Qt::UserRole + 1,
        TitleRole,
        ClassRole,
        WorkspaceIdRole,
        WorkspaceNameRole,
        OriginalXRole,
        OriginalYRole,
        OriginalWidthRole,
        OriginalHeightRole,
        TargetXRole,
        TargetYRole,
        TargetWidthRole,
        TargetHeightRole,
        IsXWaylandRole,
    };

    struct WindowInfo {
        QString address;
        QString title;
        QString className;
        int workspaceId = 0;
        QString workspaceName;
        int monitorId = -1;
        QRectF originalRect;
        QRectF targetRect;
        bool isXWayland = false;
        bool wasFloating = false;
    };

    explicit MissionControlModel(QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    bool isReady() const { return m_ready; }
    bool isExposed() const { return m_exposed; }
    bool isAnimating() const { return m_animating; }

    Q_INVOKABLE void refresh(int screenWidth, int screenHeight,
                             int monitorX, int monitorY,
                             int monitorId, int activeWorkspaceId,
                             int padding = 28);

    Q_INVOKABLE void expose();

    Q_INVOKABLE void restore(const QString& focusAddress = QString());

    Q_INVOKABLE QString windowAt(int x, int y) const;

signals:
    void countChanged();
    void readyChanged();
    void exposedChanged();
    void animatingChanged();
    void restored();

private:
    void fetchWindowsFromSocket();
    void parseAndLayout(const QByteArray& data);
    void calculateLayout(int screenWidth, int screenHeight, int padding);
    void resolveSocketPath();

    void dispatchToHyprland(const QString& command);
    void dispatchBatch(const QStringList& commands);

    void startAnimation(bool forward);
    void onAnimationTick();
    void finishExpose();
    void finishRestore();

    QVector<WindowInfo> m_windows;
    int m_screenWidth = 0;
    int m_screenHeight = 0;
    int m_monitorX = 0;
    int m_monitorY = 0;
    int m_monitorId = -1;
    int m_activeWorkspaceId = -1;
    int m_padding = 28;
    bool m_ready = false;
    bool m_exposed = false;
    bool m_animating = false;

    QTimer* m_animTimer = nullptr;
    double m_animProgress = 0.0;
    bool m_animForward = true;
    QString m_pendingFocusAddress;
    QString m_socketPath;

    static constexpr double ANIM_DURATION_MS = 500.0;
    static constexpr double ANIM_TICK_MS = 16.0;
};
