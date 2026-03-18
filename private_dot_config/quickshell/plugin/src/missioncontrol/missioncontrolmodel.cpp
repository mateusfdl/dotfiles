#include "missioncontrolmodel.hpp"

#include <QDir>
#include <QFileInfo>
#include <QProcessEnvironment>

#include <algorithm>
#include <cmath>
#include <memory>
#include <numeric>

MissionControlModel::MissionControlModel(QObject* parent)
    : QAbstractListModel(parent) {
    m_animTimer = new QTimer(this);
    m_animTimer->setTimerType(Qt::PreciseTimer);
    connect(m_animTimer, &QTimer::timeout, this, &MissionControlModel::onAnimationTick);
}

int MissionControlModel::rowCount(const QModelIndex& parent) const {
    if (parent.isValid()) return 0;
    return static_cast<int>(m_windows.size());
}

QVariant MissionControlModel::data(const QModelIndex& index, int role) const {
    if (!index.isValid() || index.row() < 0 ||
        index.row() >= static_cast<int>(m_windows.size()))
        return {};

    const auto& w = m_windows[index.row()];

    switch (role) {
        case AddressRole:        return w.address;
        case TitleRole:          return w.title;
        case ClassRole:          return w.className;
        case WorkspaceIdRole:    return w.workspaceId;
        case WorkspaceNameRole:  return w.workspaceName;
        case OriginalXRole:      return w.originalRect.x();
        case OriginalYRole:      return w.originalRect.y();
        case OriginalWidthRole:  return w.originalRect.width();
        case OriginalHeightRole: return w.originalRect.height();
        case TargetXRole:        return w.targetRect.x();
        case TargetYRole:        return w.targetRect.y();
        case TargetWidthRole:    return w.targetRect.width();
        case TargetHeightRole:   return w.targetRect.height();
        case IsXWaylandRole:     return w.isXWayland;
        default: return {};
    }
}

QHash<int, QByteArray> MissionControlModel::roleNames() const {
    return {
        {AddressRole,        "address"},
        {TitleRole,          "title"},
        {ClassRole,          "windowClass"},
        {WorkspaceIdRole,    "workspaceId"},
        {WorkspaceNameRole,  "workspaceName"},
        {OriginalXRole,      "originalX"},
        {OriginalYRole,      "originalY"},
        {OriginalWidthRole,  "originalWidth"},
        {OriginalHeightRole, "originalHeight"},
        {TargetXRole,        "targetX"},
        {TargetYRole,        "targetY"},
        {TargetWidthRole,    "targetWidth"},
        {TargetHeightRole,   "targetHeight"},
        {IsXWaylandRole,     "isXWayland"},
    };
}

void MissionControlModel::resolveSocketPath() {
    if (!m_socketPath.isEmpty()) return;

    const auto env = QProcessEnvironment::systemEnvironment();
    const auto sig = env.value(QStringLiteral("HYPRLAND_INSTANCE_SIGNATURE"));
    if (sig.isEmpty()) return;

    const auto xdgRuntime = env.value(QStringLiteral("XDG_RUNTIME_DIR"));
    if (!xdgRuntime.isEmpty()) {
        const auto path = xdgRuntime + "/hypr/" + sig + "/.socket.sock";
        if (QDir().exists(QFileInfo(path).path())) {
            m_socketPath = path;
            return;
        }
    }

    m_socketPath = "/tmp/hypr/" + sig + "/.socket.sock";
}

void MissionControlModel::dispatchToHyprland(const QString& command) {
    resolveSocketPath();
    if (m_socketPath.isEmpty()) return;

    auto* socket = new QLocalSocket(this);
    connect(socket, &QLocalSocket::connected, this, [socket, command]() {
        socket->write(("/dispatch " + command).toUtf8());
        socket->flush();
    });
    connect(socket, &QLocalSocket::readyRead, socket, [socket]() {
        socket->readAll();
        socket->disconnectFromServer();
    });
    connect(socket, &QLocalSocket::disconnected, socket, &QLocalSocket::deleteLater);
    connect(socket, &QLocalSocket::errorOccurred, socket, &QLocalSocket::deleteLater);
    socket->connectToServer(m_socketPath);
}

void MissionControlModel::dispatchBatch(const QStringList& commands) {
    resolveSocketPath();
    if (m_socketPath.isEmpty()) return;

    QString batch = QStringLiteral("[[BATCH]]");
    for (const auto& cmd : commands) {
        batch += "/dispatch " + cmd + ";";
    }

    auto* socket = new QLocalSocket(this);
    connect(socket, &QLocalSocket::connected, this, [socket, batch]() {
        socket->write(batch.toUtf8());
        socket->flush();
    });
    connect(socket, &QLocalSocket::readyRead, socket, [socket]() {
        socket->readAll();
        socket->disconnectFromServer();
    });
    connect(socket, &QLocalSocket::disconnected, socket, &QLocalSocket::deleteLater);
    connect(socket, &QLocalSocket::errorOccurred, socket, &QLocalSocket::deleteLater);
    socket->connectToServer(m_socketPath);
}

void MissionControlModel::refresh(int screenWidth, int screenHeight,
                                   int monitorX, int monitorY,
                                   int monitorId, int activeWorkspaceId,
                                   int padding) {
    m_screenWidth = screenWidth;
    m_screenHeight = screenHeight;
    m_monitorX = monitorX;
    m_monitorY = monitorY;
    m_monitorId = monitorId;
    m_activeWorkspaceId = activeWorkspaceId;
    m_padding = padding;
    fetchWindowsFromSocket();
}

void MissionControlModel::fetchWindowsFromSocket() {
    resolveSocketPath();
    if (m_socketPath.isEmpty()) {
        qWarning() << "[MissionControl] HYPRLAND_INSTANCE_SIGNATURE not set";
        return;
    }

    auto* socket = new QLocalSocket(this);
    auto buffer = std::make_shared<QByteArray>();

    connect(socket, &QLocalSocket::connected, this, [socket]() {
        socket->write("j/clients");
        socket->flush();
    });

    connect(socket, &QLocalSocket::readyRead, this, [this, socket, buffer]() {
        buffer->append(socket->readAll());

        QJsonParseError err;
        QJsonDocument::fromJson(*buffer, &err);
        if (err.error == QJsonParseError::NoError) {
            parseAndLayout(*buffer);
            socket->disconnectFromServer();
        }
    });

    connect(socket, &QLocalSocket::disconnected, socket, &QLocalSocket::deleteLater);
    connect(socket, &QLocalSocket::errorOccurred, this, [socket](QLocalSocket::LocalSocketError) {
        socket->deleteLater();
    });

    socket->connectToServer(m_socketPath);
}

void MissionControlModel::parseAndLayout(const QByteArray& data) {
    const auto doc = QJsonDocument::fromJson(data);
    if (!doc.isArray()) {
        qWarning() << "[MissionControl] Expected JSON array from hyprctl clients";
        return;
    }

    beginResetModel();
    m_windows.clear();

    const auto arr = doc.array();
    for (const auto& val : arr) {
        const auto obj = val.toObject();

        if (obj.value(QStringLiteral("hidden")).toBool(false)) continue;
        if (!obj.value(QStringLiteral("mapped")).toBool(true)) continue;

        const auto wsObj = obj.value(QStringLiteral("workspace")).toObject();
        const int wsId = wsObj.value(QStringLiteral("id")).toInt();
        if (wsId < 0) continue;

        if (wsId != m_activeWorkspaceId) continue;

        const int winMonitor = obj.value(QStringLiteral("monitor")).toInt(-1);

        WindowInfo w;
        w.address = obj.value(QStringLiteral("address")).toString();
        w.title = obj.value(QStringLiteral("title")).toString();
        w.className = obj.value(QStringLiteral("class")).toString();
        w.workspaceId = wsId;
        w.workspaceName = wsObj.value(QStringLiteral("name")).toString();
        w.monitorId = winMonitor;
        w.isXWayland = obj.value(QStringLiteral("xwayland")).toBool(false);
        w.wasFloating = obj.value(QStringLiteral("floating")).toBool(false);

        const auto at = obj.value(QStringLiteral("at")).toArray();
        const auto size = obj.value(QStringLiteral("size")).toArray();
        const qreal x = at.size() >= 2 ? at[0].toDouble() : 0;
        const qreal y = at.size() >= 2 ? at[1].toDouble() : 0;
        const qreal width = size.size() >= 2 ? size[0].toDouble() : 400;
        const qreal height = size.size() >= 2 ? size[1].toDouble() : 300;

        w.originalRect = QRectF(x, y, width, height);

        m_windows.push_back(std::move(w));
    }

    calculateLayout(m_screenWidth, m_screenHeight, m_padding);

    endResetModel();

    m_ready = true;
    emit readyChanged();
    emit countChanged();
}

void MissionControlModel::calculateLayout(int screenWidth, int screenHeight,
                                           int padding) {
    const int n = static_cast<int>(m_windows.size());
    if (n == 0) return;

    const double margin = static_cast<double>(padding);
    const double availW = screenWidth - margin * 2;
    const double availH = screenHeight - margin * 2;

    if (availW <= 0 || availH <= 0) return;

    const double screenAspect = availW / availH;

    double avgAspect = 0;
    for (const auto& w : m_windows) {
        const double ww = w.originalRect.width();
        const double wh = w.originalRect.height();
        avgAspect += (wh > 0) ? (ww / wh) : screenAspect;
    }
    avgAspect /= n;

    int cols = std::max(1, static_cast<int>(
        std::round(std::sqrt(static_cast<double>(n) * screenAspect / avgAspect))));
    int rows = std::max(1, static_cast<int>(std::ceil(static_cast<double>(n) / cols)));

    while (cols > 1 && (cols - 1) * rows >= n) cols--;
    rows = std::max(1, static_cast<int>(std::ceil(static_cast<double>(n) / cols)));

    const double gapTotalW = padding * (cols - 1);
    const double gapTotalH = padding * (rows - 1);
    const double cellW = (availW - gapTotalW) / cols;
    const double cellH = (availH - gapTotalH) / rows;

    for (int i = 0; i < n; ++i) {
        auto& w = m_windows[i];

        const int col = i % cols;
        const int row = i / cols;

        const double cellX = m_monitorX + margin + col * (cellW + padding);
        const double cellY = m_monitorY + margin + row * (cellH + padding);

        const double origW = w.originalRect.width();
        const double origH = w.originalRect.height();

        if (origW <= 0 || origH <= 0) {
            w.targetRect = QRectF(cellX, cellY, cellW, cellH);
            continue;
        }

        const double scaleX = cellW / origW;
        const double scaleY = cellH / origH;
        const double scale = std::min(scaleX, scaleY) * 0.96;

        const double targetW = origW * scale;
        const double targetH = origH * scale;

        const double targetX = cellX + (cellW - targetW) / 2.0;
        const double targetY = cellY + (cellH - targetH) / 2.0;

        w.targetRect = QRectF(targetX, targetY, targetW, targetH);
    }
}

void MissionControlModel::expose() {
    if (m_windows.isEmpty() || m_exposed || m_animating) return;

    QStringList floatCmds;
    for (const auto& w : m_windows) {
        if (!w.wasFloating) {
            floatCmds << QString("setfloating address:%1").arg(w.address);
        }
    }
    if (!floatCmds.isEmpty()) {
        dispatchBatch(floatCmds);
    }

    startAnimation(true);
}

void MissionControlModel::restore(const QString& focusAddress) {
    if (m_windows.isEmpty() || !m_exposed || m_animating) return;

    m_pendingFocusAddress = focusAddress;

    startAnimation(false);
}

void MissionControlModel::startAnimation(bool forward) {
    m_animForward = forward;
    m_animProgress = 0.0;
    m_animating = true;
    emit animatingChanged();

    m_animTimer->start(static_cast<int>(ANIM_TICK_MS));
}

void MissionControlModel::onAnimationTick() {
    m_animProgress += ANIM_TICK_MS / ANIM_DURATION_MS;

    if (m_animProgress >= 1.0) {
        m_animProgress = 1.0;
        m_animTimer->stop();
    }

    const double raw = m_animProgress;
    const double inv = 1.0 - raw;
    const double t = 1.0 - (inv * inv * inv * inv);

    QStringList cmds;
    cmds.reserve(m_windows.size() * 2);

    for (const auto& w : m_windows) {
        double fromLeft, fromTop, fromRight, fromBottom;
        double toLeft, toTop, toRight, toBottom;

        if (m_animForward) {
            fromLeft   = w.originalRect.left();
            fromTop    = w.originalRect.top();
            fromRight  = w.originalRect.right();
            fromBottom = w.originalRect.bottom();
            toLeft     = w.targetRect.left();
            toTop      = w.targetRect.top();
            toRight    = w.targetRect.right();
            toBottom   = w.targetRect.bottom();
        } else {
            fromLeft   = w.targetRect.left();
            fromTop    = w.targetRect.top();
            fromRight  = w.targetRect.right();
            fromBottom = w.targetRect.bottom();
            toLeft     = w.originalRect.left();
            toTop      = w.originalRect.top();
            toRight    = w.originalRect.right();
            toBottom   = w.originalRect.bottom();
        }

        const double curLeft   = fromLeft   + (toLeft   - fromLeft)   * t;
        const double curTop    = fromTop    + (toTop    - fromTop)    * t;
        const double curRight  = fromRight  + (toRight  - fromRight)  * t;
        const double curBottom = fromBottom + (toBottom - fromBottom) * t;

        const int curX = static_cast<int>(curLeft);
        const int curY = static_cast<int>(curTop);
        const int curW = std::max(1, static_cast<int>(curRight - curLeft));
        const int curH = std::max(1, static_cast<int>(curBottom - curTop));

        cmds << QString("movewindowpixel exact %1 %2,address:%3")
                    .arg(curX).arg(curY).arg(w.address);
        cmds << QString("resizewindowpixel exact %1 %2,address:%3")
                    .arg(curW).arg(curH).arg(w.address);
    }

    dispatchBatch(cmds);

    if (m_animProgress >= 1.0) {
        m_animating = false;
        emit animatingChanged();

        if (m_animForward) {
            finishExpose();
        } else {
            finishRestore();
        }
    }
}

void MissionControlModel::finishExpose() {
    m_exposed = true;
    emit exposedChanged();
}

void MissionControlModel::finishRestore() {
    QStringList cmds;

    for (const auto& w : m_windows) {
        if (!w.wasFloating) {
            cmds << QString("settiled address:%1").arg(w.address);
        }
    }

    if (!m_pendingFocusAddress.isEmpty()) {
        cmds << QString("focuswindow address:%1").arg(m_pendingFocusAddress);
    }

    if (!cmds.isEmpty()) {
        dispatchBatch(cmds);
    }

    m_exposed = false;
    emit exposedChanged();
    emit restored();
}

QString MissionControlModel::windowAt(int x, int y) const {
    const double px = static_cast<double>(x) + m_monitorX;
    const double py = static_cast<double>(y) + m_monitorY;

    for (int i = m_windows.size() - 1; i >= 0; --i) {
        if (m_windows[i].targetRect.contains(px, py)) {
            return m_windows[i].address;
        }
    }
    return {};
}
