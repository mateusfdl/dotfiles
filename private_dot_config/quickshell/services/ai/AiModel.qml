import QtQuick

QtObject {
    property string name
    property string icon
    property string description
    property string endpoint
    property string model
    property bool requires_key: true
    property string key_env_var
    property var extraParams: ({})
}
