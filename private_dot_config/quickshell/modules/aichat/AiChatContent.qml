import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Rectangle {
    id: root
    signal closeRequested()
    property string commandPrefix: "/"

    implicitWidth: 680
    implicitHeight: 600

    radius: 20
    color: Appearance.colors.colLayer1
    border.color: Appearance.m3colors.m3borderSecondary
    border.width: 1

    layer.enabled: true
    layer.effect: DropShadow {
        horizontalOffset: 0
        verticalOffset: 10
        radius: 30
        samples: 31
        color: Appearance.m3colors.m3shadowColor
        opacity: 0
    }

    property var allCommands: [
        {
            name: "model",
            description: "Set the AI model",
            execute: args => {
                if (args.length === 0) {
                    Ai.addMessage("Available models:\n- " + Ai.modelList.join("\n- "), Ai.interfaceRole);
                } else {
                    Ai.setModel(args[0]);
                }
            }
        },
        {
            name: "temp",
            description: "Set temperature (0-2)",
            execute: args => {
                if (args.length === 0) {
                    Ai.addMessage(`Current temperature: **${Ai.temperature}**`, Ai.interfaceRole);
                } else {
                    Ai.setTemperature(parseFloat(args[0]));
                }
            }
        },
        {
            name: "clear",
            description: "Clear chat history",
            execute: () => {
                Ai.clearMessages();
            }
        },
        {
            name: "help",
            description: "Show available commands",
            execute: () => {
                let helpText = "**Available Commands:**\n";
                root.allCommands.forEach(cmd => {
                    helpText += `\n- \`${commandPrefix}${cmd.name}\` - ${cmd.description}`;
                });
                Ai.addMessage(helpText, Ai.interfaceRole);
            }
        },
        {
            name: "system",
            description: "Set system prompt",
            execute: args => {
                if (args.length === 0) {
                    Ai.addMessage(`Current system prompt:\n\n${Ai.systemPrompt}`, Ai.interfaceRole);
                } else {
                    Ai.systemPrompt = args.join(" ");
                    Ai.addMessage("System prompt updated.", Ai.interfaceRole);
                }
            }
        }
    ]

    function handleInput(inputText) {
        const trimmedText = inputText.trim();
        if (trimmedText.length === 0) return;

        if (trimmedText.startsWith(commandPrefix)) {
            const commandParts = trimmedText.slice(commandPrefix.length).split(/\s+/);
            const commandName = commandParts[0].toLowerCase();
            const args = commandParts.slice(1);

            const command = allCommands.find(cmd => cmd.name === commandName);
            if (command) {
                command.execute(args);
            } else {
                Ai.addMessage(`Unknown command: \`${commandName}\`. Type \`${commandPrefix}help\` for available commands.`, Ai.interfaceRole);
            }
        } else {
            Ai.sendUserMessage(trimmedText);
        }
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            GlobalStates.aiChatOpen = false;
            event.accepted = true;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            MaterialSymbol {
                text: "auto_awesome"
                iconSize: 28
                fill: 1
                color: Appearance.colors.colPrimary
            }

            Text {
                text: "AI Chat"
                font.family: Appearance.font.family.uiFont
                font.pixelSize: 22
                font.bold: true
                color: Appearance.m3colors.m3primaryText
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                implicitWidth: modelLabel.implicitWidth + 16
                implicitHeight: modelLabel.implicitHeight + 8
                radius: Appearance.rounding.small
                color: Appearance.colors.colLayer2

                Text {
                    id: modelLabel
                    anchors.centerIn: parent
                    text: Ai.models[Ai.currentModelId]?.name || Ai.currentModelId
                    font.family: Appearance.font.family.uiFont
                    font.pixelSize: Appearance.font.pixelSize.textSmall
                    color: Appearance.m3colors.m3secondaryText
                }
            }

            Rectangle {
                id: closeButton
                implicitWidth: 36
                implicitHeight: 36
                radius: Appearance.rounding.full
                color: closeMouseArea.containsMouse ? Appearance.colors.colLayer2 : "transparent"

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "close"
                    iconSize: 22
                    color: Appearance.m3colors.m3primaryText
                }

                MouseArea {
                    id: closeMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.closeRequested()
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Appearance.m3colors.m3borderSecondary
        }

        ListView {
            id: messageListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 8

            model: Ai.messageIDs

            delegate: AiMessage {
                required property string modelData
                required property int index
                width: messageListView.width
                messageData: Ai.messageByID[modelData] ?? ({})
                messageIndex: index
            }

            ScrollBar.vertical: StyledScrollBar {
                policy: ScrollBar.AsNeeded
            }

            onCountChanged: {
                Qt.callLater(() => {
                    messageListView.positionViewAtEnd();
                });
            }

            Connections {
                target: Ai
                function onResponseFinished() {
                    messageListView.positionViewAtEnd();
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Appearance.m3colors.m3borderSecondary
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                id: inputContainer
                Layout.fillWidth: true
                implicitHeight: 52
                radius: 12
                color: Appearance.colors.colLayer2
                border.width: inputField.activeFocus ? 2 : 0
                border.color: inputField.activeFocus ? Appearance.colors.colPrimary : "transparent"

                Behavior on border.color {
                    ColorAnimation { duration: 150 }
                }

                TextField {
                    id: inputField
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    verticalAlignment: TextInput.AlignVCenter
                    topPadding: 0
                    bottomPadding: 0
                    leftPadding: 0
                    rightPadding: 0
                    placeholderText: "Type a message... (/ for commands)"
                    font.family: Appearance.font.family.uiFont
                    font.pixelSize: 15
                    color: Appearance.m3colors.m3primaryText
                    placeholderTextColor: Appearance.m3colors.m3secondaryText
                    background: Item {}

                    Keys.onReturnPressed: event => {
                        if (inputField.text.trim().length > 0) {
                            root.handleInput(inputField.text);
                            inputField.text = "";
                        }
                    }

                    Component.onCompleted: {
                        forceActiveFocus();
                    }

                    Connections {
                        target: GlobalStates
                        function onAiChatOpenChanged(): void {
                            if (GlobalStates.aiChatOpen)
                                inputField.forceActiveFocus();
                        }
                    }
                }
            }

            RippleButton {
                implicitWidth: 48
                implicitHeight: 48
                buttonRadius: Appearance.rounding.full
                colBackground: Appearance.colors.colPrimary
                colBackgroundHover: Appearance.colors.colPrimaryHover

                contentItem: MaterialSymbol {
                    text: "send"
                    iconSize: 24
                    color: Appearance.m3colors.m3accentPrimaryText
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: {
                    if (inputField.text.trim().length > 0) {
                        root.handleInput(inputField.text);
                        inputField.text = "";
                    }
                }
            }
        }
    }
}
