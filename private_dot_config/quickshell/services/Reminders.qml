pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import QsUtils as QsUtilsPlugin

Singleton {
    id: root

    readonly property string namespaceName: "reminders"
    property var reminders: []
    property var activeReminders: []

    function refresh() {
        const states = store.values(root.namespaceName);
        const reminders = [];
        const activeReminders = [];
        const liveUuids = new Set();

        for (let index = 0; index < QsUtilsPlugin.Tasks.todos.length; index++) {
            const todo = Object.assign({}, QsUtilsPlugin.Tasks.todos[index]);
            liveUuids.add(todo.uuid);
            let isActive = true;
            if (states[todo.uuid] !== undefined)
                isActive = states[todo.uuid];

            todo.isActive = isActive;
            reminders.push(todo);
            if (isActive)
                activeReminders.push(todo);
        }

        for (const key in states) {
            if (!liveUuids.has(key))
                store.removeValue(root.namespaceName, key);
        }

        root.reminders = reminders;
        root.activeReminders = activeReminders;
    }

    function toggle(id) {
        for (let index = 0; index < root.reminders.length; index++) {
            const reminder = root.reminders[index];
            if (reminder.uuid !== id)
                continue;

            const updated = store.setValue(root.namespaceName, id, !reminder.isActive);
            if (updated)
                root.refresh();
            return updated;
        }

        return false;
    }

    Connections {
        target: QsUtilsPlugin.Tasks
        function onTodosChanged() {
            root.refresh();
        }
    }

    Connections {
        target: Sqlite
        function onReadyChanged() {
            if (Sqlite.ready)
                root.refresh();
        }
    }

    QsUtilsPlugin.KeyValueStore {
        id: store
        database: Sqlite.database
        onError: message => console.error("[Reminders] " + message)
    }
}
