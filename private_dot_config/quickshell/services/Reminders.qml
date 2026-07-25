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

        for (let index = 0; index < QsUtilsPlugin.Tasks.todos.length; index++) {
            const todo = Object.assign({}, QsUtilsPlugin.Tasks.todos[index]);
            let isActive = true;
            if (states[todo.uuid] !== undefined)
                isActive = states[todo.uuid];

            todo.isActive = isActive;
            reminders.push(todo);
            if (isActive)
                activeReminders.push(todo);
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

    QsUtilsPlugin.KeyValueStore {
        id: store
        database: Sqlite.database
        onError: message => console.error("[Reminders] " + message)
    }
}
