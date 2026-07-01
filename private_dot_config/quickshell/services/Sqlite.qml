pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import QsUtils as QsUtilsPlugin
import qs.modules.common

Singleton {
    id: root

    readonly property string dbDir: Config.options.sqlite.dbDir
    readonly property string dbName: Config.options.sqlite.dbName
    readonly property string dbPath: `${root.dbDir}/${root.dbName}`
    readonly property string migrationsDir: Config.options.sqlite.migrationsDir
    readonly property bool ready: database.open

    function query(sql, bindings) {
        let resolvedBindings = bindings;
        if (resolvedBindings === undefined)
            resolvedBindings = [];
        return database.query(sql, resolvedBindings);
    }

    function exec(sql, bindings) {
        let resolvedBindings = bindings;
        if (resolvedBindings === undefined)
            resolvedBindings = [];
        return database.exec(sql, resolvedBindings);
    }

    QsUtilsPlugin.Sqlite {
        id: database
        path: root.dbPath
        onOpenChanged: {
            if (database.open)
                database.migrate(root.migrationsDir);
        }
        onError: message => console.error("[Sqlite] " + message)
    }
}
