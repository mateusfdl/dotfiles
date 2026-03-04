import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services

Item {
    id: root
    required property var messageData
    required property int messageIndex

    property bool isUser: messageData?.role === "user"
    property bool isInterface: messageData?.role === Ai.interfaceRole
    property bool isTool: messageData?.role === "tool"
    property bool hasToolCalls: (messageData?.toolCalls?.length ?? 0) > 0
    property bool isThinking: (messageData?.thinking ?? false) && !(messageData?.done ?? true)

    // Syntax highlighting colors from theme
    readonly property var highlightColors: ({
        keyword: Appearance.m3colors.m3accentSecondary,
        string: "#9ece6a",
        comment: Appearance.m3colors.m3secondaryText,
        number: Appearance.m3colors.m3accentPrimary,
        function: Appearance.m3colors.m3borderPrimary,
        builtin: "#2ac3de",
        variable: "#ff9e64",
        operator: Appearance.m3colors.m3accentSecondary,
        punctuation: Appearance.m3colors.m3primaryText,
        text: Appearance.m3colors.m3primaryText,
        codeBackground: Appearance.colors.colLayer1,
        codeBorder: Appearance.m3colors.m3borderSecondary,
        inlineCodeBackground: Appearance.m3colors.m3layerBackground3,
        linkColor: Appearance.m3colors.m3accentPrimary
    })

    // Process markdown content with syntax highlighting
    readonly property var processedContent: {
        const content = messageData?.content ?? "";
        if (!content) return { html: "", missingColors: [] };
        return MarkdownHighlight.markdownToHtml(content, highlightColors);
    }

    // Show warning for missing colors
    onProcessedContentChanged: {
        if (processedContent.missingColors && processedContent.missingColors.length > 0) {
            console.warn("[AiMessage] Missing highlight colors:", processedContent.missingColors.join(", "));
        }
    }

    // Hide tool messages from display
    visible: !isTool
    implicitWidth: parent?.width ?? 0
    implicitHeight: isTool ? 0 : messageLayout.implicitHeight + 12

    RowLayout {
        id: messageLayout
        anchors.fill: parent
        anchors.leftMargin: isUser ? 40 : 4
        anchors.rightMargin: isUser ? 4 : 40
        spacing: 10

        layoutDirection: isUser ? Qt.RightToLeft : Qt.LeftToRight

        Rectangle {
            id: messageContainer
            Layout.fillWidth: true
            Layout.maximumWidth: parent.width
            Layout.preferredHeight: contentColumn.implicitHeight + 20
            radius: 16
            color: isUser ? Appearance.colors.colPrimary
                 : isInterface ? Appearance.colors.colLayer2
                 : Appearance.colors.colLayer2

            ColumnLayout {
                id: contentColumn
                anchors.fill: parent
                anchors.margins: 12
                spacing: 6

                RowLayout {
                    visible: !isUser && !isInterface
                    Layout.fillWidth: true
                    spacing: 8

                    MaterialSymbol {
                        text: "auto_awesome"
                        iconSize: 16
                        fill: 1
                        color: Appearance.colors.colPrimary
                    }

                    Text {
                        Layout.fillWidth: true
                        text: messageData?.model ? (Ai.models[messageData.model]?.name ?? messageData.model) : ""
                        font.family: Appearance.font.family.uiFont
                        font.pixelSize: 12
                        font.bold: true
                        color: Appearance.m3colors.m3secondaryText
                        elide: Text.ElideRight
                    }
                }

                RowLayout {
                    visible: isThinking
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "Thinking"
                        font.family: Appearance.font.family.uiFont
                        font.pixelSize: 14
                        font.italic: true
                        color: Appearance.m3colors.m3secondaryText
                    }

                    // Animated dots
                    Row {
                        spacing: 4
                        Repeater {
                            model: 3
                            Rectangle {
                                width: 6
                                height: 6
                                radius: 3
                                color: Appearance.m3colors.m3secondaryText

                                SequentialAnimation on opacity {
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 0.3; duration: 300; easing.type: Easing.InOutQuad }
                                    NumberAnimation { to: 1.0; duration: 300; easing.type: Easing.InOutQuad }
                                    PauseAnimation { duration: index * 150 }
                                }
                            }
                        }
                    }
                }

                // Tool call indicator
                RowLayout {
                    visible: hasToolCalls && (messageData?.content?.length ?? 0) === 0
                    Layout.fillWidth: true
                    spacing: 8

                    MaterialSymbol {
                        text: "build"
                        iconSize: 16
                        fill: 1
                        color: Appearance.colors.colPrimary
                    }

                    Text {
                        text: "Executing action..."
                        font.family: Appearance.font.family.uiFont
                        font.pixelSize: 14
                        font.italic: true
                        color: Appearance.m3colors.m3secondaryText
                    }
                }

                TextEdit {
                    id: messageText
                    visible: !isThinking || (messageData?.content?.length ?? 0) > 0
                    Layout.fillWidth: true
                    text: isUser ? (messageData?.content ?? "") : processedContent.html
                    font.family: Appearance.font.family.uiFont
                    font.pixelSize: 15
                    color: isUser ? Appearance.m3colors.m3accentPrimaryText
                         : isInterface ? Appearance.m3colors.m3secondaryText
                         : Appearance.m3colors.m3primaryText
                    wrapMode: Text.Wrap
                    readOnly: true
                    selectByMouse: true
                    textFormat: isUser ? TextEdit.PlainText : TextEdit.RichText
                }
            }
        }
    }
}
