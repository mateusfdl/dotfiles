#include "hyprlandworkspace.hpp"

#include <QFile>
#include <QProcessEnvironment>
#include <algorithm>

#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>

#include <array>
#include <cstring>

HyprlandWorkspace::HyprlandWorkspace(QObject* parent) : QObject(parent) {}

int HyprlandWorkspace::navigateForward(const QList<int>& workspaceIds, int currentId) {
    if (workspaceIds.isEmpty()) return -1;

    auto sorted = workspaceIds;
    std::sort(sorted.begin(), sorted.end());

    const auto it = std::find(sorted.cbegin(), sorted.cend(), currentId);
    if (it == sorted.cend() || std::next(it) == sorted.cend()) return -1;

    return *std::next(it);
}

int HyprlandWorkspace::navigateBackward(const QList<int>& workspaceIds, int currentId) {
    if (workspaceIds.isEmpty()) return -1;

    auto sorted = workspaceIds;
    std::sort(sorted.begin(), sorted.end());

    const auto it = std::find(sorted.cbegin(), sorted.cend(), currentId);
    if (it == sorted.cend() || it == sorted.cbegin()) return -1;

    return *std::prev(it);
}

int HyprlandWorkspace::insertWorkspaceAfter(const QList<int>& workspaceIds, int currentId) {
    if (currentId < 0) return -1;

    const int newSlot = currentId + 1;

    auto sorted = workspaceIds;
    std::sort(sorted.begin(), sorted.end());

    // Rename workspaces >= newSlot in reverse order to avoid ID collisions
    for (auto it = sorted.crbegin(); it != sorted.crend(); ++it) {
        if (*it >= newSlot) {
            const auto cmd = QStringLiteral("renameworkspace %1 %2").arg(*it).arg(*it + 1);
            if (!hyprlandDispatch(cmd)) {
                return -1;
            }
        }
    }

    return newSlot;
}

QString HyprlandWorkspace::hyprlandSocketPath() {
    const auto env = QProcessEnvironment::systemEnvironment();
    const auto sig = env.value(QStringLiteral("HYPRLAND_INSTANCE_SIGNATURE"));

    if (sig.isEmpty()) return {};

    // Modern Hyprland uses $XDG_RUNTIME_DIR/hypr/, older versions use /tmp/hypr/
    const auto xdgRuntime = env.value(QStringLiteral("XDG_RUNTIME_DIR"));
    if (!xdgRuntime.isEmpty()) {
        const auto path = QStringLiteral("%1/hypr/%2/.socket.sock").arg(xdgRuntime, sig);
        if (QFile::exists(path)) return path;
    }

    return QStringLiteral("/tmp/hypr/%1/.socket.sock").arg(sig);
}

bool HyprlandWorkspace::hyprlandDispatch(const QString& command) {
    const auto socketPath = hyprlandSocketPath();
    if (socketPath.isEmpty()) return false;

    const int fd = ::socket(AF_UNIX, SOCK_STREAM, 0);
    if (fd < 0) return false;

    struct sockaddr_un addr{};
    addr.sun_family = AF_UNIX;

    const auto pathBytes = socketPath.toUtf8();
    if (static_cast<size_t>(pathBytes.size()) >= sizeof(addr.sun_path)) {
        ::close(fd);
        return false;
    }
    std::memcpy(addr.sun_path, pathBytes.constData(), static_cast<size_t>(pathBytes.size()));

    if (::connect(fd, reinterpret_cast<struct sockaddr*>(&addr), sizeof(addr)) < 0) {
        ::close(fd);
        return false;
    }

    // Hyprland expects: "dispatch <command>\n" or just "dispatch <command>"
    const auto payload = QStringLiteral("dispatch %1").arg(command).toUtf8();
    const auto written = ::write(fd, payload.constData(), static_cast<size_t>(payload.size()));

    if (written < 0 || written != payload.size()) {
        ::close(fd);
        return false;
    }

    // Read response (Hyprland sends "ok" on success)
    std::array<char, 256> buf{};
    const auto bytesRead = ::read(fd, buf.data(), buf.size() - 1);
    ::close(fd);

    if (bytesRead <= 0) return false;

    const auto response = QString::fromUtf8(buf.data(), static_cast<int>(bytesRead)).trimmed();
    return response == QStringLiteral("ok");
}
