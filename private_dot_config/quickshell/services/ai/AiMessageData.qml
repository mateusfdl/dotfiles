import QtQuick

QtObject {
    property string role
    property string content
    property string rawContent
    property string model
    property bool thinking: true
    property bool done: false
    property string toolCallId: ""
    property var toolCalls: []
}
