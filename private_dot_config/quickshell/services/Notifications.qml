pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    component Notif: QtObject {
        required property int notificationId
        property Notification notification
        property list<var> actions: notification?.actions.map(action => ({
                    "identifier": action.identifier,
                    "text": action.text
                })) ?? []
        property bool popup: false
        property string appIcon: notification?.appIcon ?? ""
        property string appName: notification?.appName ?? ""
        property string body: notification?.body ?? ""
        property string image: notification?.image ?? ""
        property string summary: notification?.summary ?? ""
        property double time
        property int urgency: notification?.urgency ?? NotificationUrgency.Normal
        property Timer timer

        onNotificationChanged: {
            if (notification === null)
                root.discardNotification(notificationId);
        }
    }

    component NotifTimer: Timer {
        required property int notificationId
        running: true
        onTriggered: () => {
            root.timeoutNotification(notificationId);
            destroy();
        }
    }

    property list<Notif> list: []
    readonly property var popupList: list.filter(notif => notif.popup)
    readonly property var popupGroupsByAppName: groupsForList(popupList)
    readonly property var popupAppNameList: appNameListForGroups(popupGroupsByAppName)

    Component {
        id: notifComponent
        Notif {}
    }

    Component {
        id: notifTimerComponent
        NotifTimer {}
    }

    NotificationServer {
        id: notifServer
        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        bodySupported: true
        imageSupported: true
        keepOnReload: false
        persistenceSupported: true

        onNotification: notification => {
            notification.tracked = true;
            const notif = notifComponent.createObject(root, {
                "notificationId": notification.id,
                "notification": notification,
                "time": Date.now(),
                "popup": true
            });
            root.list = [...root.list, notif];

            if (notification.expireTimeout !== 0) {
                notif.timer = notifTimerComponent.createObject(root, {
                    "notificationId": notif.notificationId,
                    "interval": notification.expireTimeout < 0 ? 7000 : notification.expireTimeout
                });
            }
        }
    }

    function groupsForList(notifs) {
        const groups = {};
        for (const notif of notifs) {
            const group = groups[notif.appName] ?? (groups[notif.appName] = {
                notifications: [],
                time: 0
            });
            group.notifications.push(notif);
            group.time = Math.max(group.time, notif.time);
        }
        return groups;
    }

    function appNameListForGroups(groups) {
        return Object.keys(groups).sort((a, b) => groups[b].time - groups[a].time);
    }

    function discardNotification(id) {
        root.list = root.list.filter(notif => notif.notificationId !== id);
        const serverNotif = notifServer.trackedNotifications.values.find(notif => notif.id === id);
        if (serverNotif)
            serverNotif.dismiss();
    }

    function timeoutNotification(id) {
        const notif = root.list.find(notif => notif.notificationId === id);
        if (notif)
            notif.popup = false;
    }

    function attemptInvokeAction(id, actionIdentifier) {
        const serverNotif = notifServer.trackedNotifications.values.find(notif => notif.id === id);
        const action = serverNotif?.actions.find(action => action.identifier === actionIdentifier);
        if (action)
            action.invoke();
        root.discardNotification(id);
    }
}
