import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.overview
import qs.modules.topbar
import qs.services

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: testWindow

            required property var modelData

            screen: modelData
            visible: true
            color: Qt.rgba(0, 0, 0, 0.1)

            anchors {
                left: true
                right: true
                top: true
                bottom: true
            }

            HyprlandFocusGrab {
                id: focusGrab

                windows: [testWindow]
                active: true
            }
            // Center container

            Rectangle {
                id: testContainer

                anchors.centerIn: parent
                width: 1280
                height: 1280
                color: Appearance.colors.colBackground
                radius: Appearance.rounding.medium

                StyledFlickable {
                    anchors.fill: parent
                    anchors.margins: 40
                    contentHeight: mainColumn.implicitHeight
                    clip: true

                    ColumnLayout {
                        id: mainColumn

                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 30
                        width: 600

                        // Section: Text Inputs
                        StyledText {
                            text: "Text Inputs"
                            font.pixelSize: 20
                            font.weight: Font.Bold
                        }

                        MaterialTextField {
                            id: textField1

                            Layout.fillWidth: true
                            placeholderText: "Enter some text..."
                            text: "Hello World"
                        }

                        MaterialTextField {
                            id: textField2

                            Layout.fillWidth: true
                            placeholderText: "Another text field..."
                        }
                        // Section: Progress Bars

                        StyledText {
                            text: "Progress Bars"
                            font.pixelSize: 20
                            font.weight: Font.Bold
                            Layout.topMargin: 20
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 20

                            StyledProgressBar {
                                id: progressBar1

                                Layout.fillWidth: true
                                value: 0.65
                                valueBarWidth: 200
                            }

                            StyledProgressBar {
                                id: progressBar2

                                Layout.fillWidth: true
                                value: 0.35
                                valueBarWidth: 200
                                wavy: true
                            }

                        }
                        // Section: Circular Progress

                        StyledText {
                            text: "Circular Progress"
                            font.pixelSize: 20
                            font.weight: Font.Bold
                            Layout.topMargin: 20
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 30

                            CircularProgress {
                                value: 0.75
                                implicitSize: 60
                                lineWidth: 4
                            }

                            CircularProgress {
                                value: 0.45
                                implicitSize: 60
                                lineWidth: 4
                                fill: true
                            }

                            CircularProgress {
                                value: 0.25
                                implicitSize: 60
                                lineWidth: 6
                            }

                        }
                        // Section: Buttons

                        StyledText {
                            text: "Buttons"
                            font.pixelSize: 20
                            font.weight: Font.Bold
                            Layout.topMargin: 20
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 15

                            DialogButton {
                                buttonText: "Dialog Button"
                                onClicked: {
                                    console.log("Dialog button clicked!");
                                }
                            }

                            RippleButton {
                                buttonText: "Ripple Button"
                                implicitWidth: 150
                                onClicked: {
                                    console.log("Ripple button clicked!");
                                }
                            }

                            RippleButton {
                                buttonText: "Toggled"
                                toggled: true
                                implicitWidth: 150
                                onClicked: {
                                    toggled = !toggled;
                                }
                            }

                        }
                        // Section: Sliders

                        StyledText {
                            text: "Sliders"
                            font.pixelSize: 20
                            font.weight: Font.Bold
                            Layout.topMargin: 20
                        }

                        StyledSlider {
                            id: slider1

                            Layout.fillWidth: true
                            value: 0.6
                            configuration: StyledSlider.Configuration.M
                        }

                        StyledSlider {
                            id: slider2

                            Layout.fillWidth: true
                            value: 0.4
                            configuration: StyledSlider.Configuration.Wavy
                        }
                        // Section: Switches

                        StyledText {
                            text: "Switches"
                            font.pixelSize: 20
                            font.weight: Font.Bold
                            Layout.topMargin: 20
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 30

                            StyledSwitch {
                                id: switch1

                                checked: true
                            }

                            StyledSwitch {
                                id: switch2

                                checked: false
                            }

                            StyledSwitch {
                                id: switch3

                                checked: true
                                scale: 0.8
                            }

                        }
                        // Interactive Demo Section

                        StyledText {
                            text: "Interactive Demo"
                            font.pixelSize: 20
                            font.weight: Font.Bold
                            Layout.topMargin: 20
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 15

                            DialogButton {
                                buttonText: "Animate Progress"
                                onClicked: {
                                    progressBar1.value = Math.random();
                                    progressBar2.value = Math.random();
                                }
                            }

                            StyledText {
                                text: `Slider value: ${Math.round(slider1.value * 100)}%`
                            }

                        }
                        // Section: Text Area

                        StyledText {
                            text: "Text Area (Multi-line)"
                            font.pixelSize: 20
                            font.weight: Font.Bold
                            Layout.topMargin: 20
                        }

                        MaterialTextArea {
                            id: textArea

                            Layout.fillWidth: true
                            Layout.preferredHeight: 100
                            placeholderText: "Enter multiple lines of text..."
                            text: "This is a multi-line\ntext area component\nwith Material 3 styling"
                        }
                        // Section: SpinBox

                        StyledText {
                            text: "SpinBox (Number Input)"
                            font.pixelSize: 20
                            font.weight: Font.Bold
                            Layout.topMargin: 20
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 20

                            StyledSpinBox {
                                id: spinBox1

                                from: 0
                                to: 100
                                value: 50
                            }

                            StyledSpinBox {
                                id: spinBox2

                                from: -50
                                to: 50
                                value: 0
                            }

                            StyledText {
                                text: `Values: ${spinBox1.value}, ${spinBox2.value}`
                            }

                        }
                        // Section: Radio Buttons

                        StyledText {
                            text: "Radio Buttons"
                            font.pixelSize: 20
                            font.weight: Font.Bold
                            Layout.topMargin: 20
                        }

                        QQC.ButtonGroup {
                            id: radioGroup
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            StyledRadioButton {
                                id: radio1

                                description: "Option 1 - Default choice"
                                checked: true
                                QQC.ButtonGroup.group: radioGroup
                            }

                            StyledRadioButton {
                                id: radio2

                                description: "Option 2 - Alternative"
                                QQC.ButtonGroup.group: radioGroup
                            }

                            StyledRadioButton {
                                id: radio3

                                description: "Option 3 - Another choice"
                                QQC.ButtonGroup.group: radioGroup
                            }

                        }
                        // Section: Button Groups

                        StyledText {
                            text: "Button Groups (with bounce)"
                            font.pixelSize: 20
                            font.weight: Font.Bold
                            Layout.topMargin: 20
                        }

                        ButtonGroup {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 8
                            padding: 4

                            GroupButton {
                                buttonText: "First"
                                onClicked: {
                                    console.log("First clicked");
                                }
                            }

                            GroupButton {
                                buttonText: "Second"
                                onClicked: {
                                    console.log("Second clicked");
                                }
                            }

                            GroupButton {
                                buttonText: "Third"
                                toggled: true
                                onClicked: {
                                    toggled = !toggled;
                                }
                            }

                        }
                        // Section: Floating Action Button

                        StyledText {
                            text: "Floating Action Button"
                            font.pixelSize: 20
                            font.weight: Font.Bold
                            Layout.topMargin: 20
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 20

                            FloatingActionButton {
                                id: fab1

                                iconText: "add"
                                onClicked: {
                                    console.log("FAB clicked!");
                                }
                            }

                            FloatingActionButton {
                                id: fab2

                                iconText: "edit"
                                buttonText: "Edit"
                                expanded: true
                                onClicked: {
                                    expanded = !expanded;
                                }
                            }

                            FloatingActionButton {
                                id: fab3

                                iconText: "save"
                                buttonText: "Save"
                                expanded: false
                                onClicked: {
                                    expanded = !expanded;
                                }
                            }

                        }
                        // Section: Notice Box

                        StyledText {
                            text: "Notice Box"
                            font.pixelSize: 20
                            font.weight: Font.Bold
                            Layout.topMargin: 20
                        }

                        NoticeBox {
                            Layout.fillWidth: true
                            materialIcon: "info"
                            text: "This is an informational notice box with Material 3 styling!"
                        }

                        NoticeBox {
                            Layout.fillWidth: true
                            materialIcon: "warning"
                            text: "This is a warning message that spans multiple lines to show text wrapping behavior in the notice component."
                        }
                        // Section: Labels

                        StyledText {
                            text: "Labels"
                            font.pixelSize: 20
                            font.weight: Font.Bold
                            Layout.topMargin: 20
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 15

                            StyledLabel {
                                text: "Default Label"
                            }

                            StyledLabel {
                                text: "Large Label"
                                font.pixelSize: 18
                            }

                            StyledLabel {
                                text: "Bold Label"
                                font.weight: Font.Bold
                            }

                        }
                        // Section: Icons

                        StyledText {
                            text: "Icons"
                            font.pixelSize: 20
                            font.weight: Font.Bold
                            Layout.topMargin: 20
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 20

                            MaterialSymbol {
                                text: "home"
                                iconSize: 32
                            }

                            MaterialSymbol {
                                text: "settings"
                                iconSize: 32
                            }

                            MaterialSymbol {
                                text: "favorite"
                                iconSize: 32
                                fill: 1
                            }

                            NerdIconImage {
                                icon: "\uf303"
                                size: 32
                            }

                        }
                        // Section: Menu & Icon Buttons

                        StyledText {
                            text: "Menu & Icon Buttons"
                            font.pixelSize: 20
                            font.weight: Font.Bold
                            Layout.topMargin: 20
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 15

                            MenuButton {
                                buttonText: "Menu Item 1"
                                onClicked: {
                                    console.log("Menu 1 clicked");
                                }
                            }

                            MenuButton {
                                buttonText: "Menu Item 2"
                                onClicked: {
                                    console.log("Menu 2 clicked");
                                }
                            }

                            RippleButtonWithIcon {
                                buttonText: "With Icon"
                                materialIcon: "star"
                                onClicked: {
                                    console.log("Icon button clicked");
                                }
                            }

                        }
                        // Section: Button Group Variants

                        StyledText {
                            text: "Button Group Variants"
                            font.pixelSize: 20
                            font.weight: Font.Bold
                            Layout.topMargin: 20
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 30

                            VerticalButtonGroup {
                                spacing: 4
                                padding: 4

                                GroupButton {
                                    buttonText: "Top"
                                }

                                GroupButton {
                                    buttonText: "Middle"
                                    toggled: true
                                }

                                GroupButton {
                                    buttonText: "Bottom"
                                }

                            }

                            FlowButtonGroup {
                                width: 200
                                spacing: 4
                                padding: 4

                                GroupButton {
                                    buttonText: "Flow 1"
                                }

                                GroupButton {
                                    buttonText: "Flow 2"
                                }

                                GroupButton {
                                    buttonText: "Flow 3"
                                }

                                GroupButton {
                                    buttonText: "Flow 4"
                                }

                            }

                        }
                        // Section: Tab Buttons

                        StyledText {
                            text: "Tab Buttons"
                            font.pixelSize: 20
                            font.weight: Font.Bold
                            Layout.topMargin: 20
                        }

                        PrimaryTabBar {
                            Layout.alignment: Qt.AlignHCenter
                            tabButtonList: [
                                {"icon": "home", "name": "First Tab"},
                                {"icon": "settings", "name": "Second Tab"},
                                {"icon": "favorite", "name": "Third Tab"}
                            ]
                            externalTrackedTab: 0

                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: 10
                            spacing: 10

                            SecondaryTabButton {
                                text: "Secondary 1"
                                checked: true
                            }

                            SecondaryTabButton {
                                text: "Secondary 2"
                            }

                            SecondaryTabButton {
                                text: "Secondary 3"
                            }

                        }
                        // Section: Additional Progress Indicators

                        StyledText {
                            text: "Additional Progress Indicators"
                            font.pixelSize: 20
                            font.weight: Font.Bold
                            Layout.topMargin: 20
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 15

                            StyledIndeterminateProgressBar {
                                Layout.fillWidth: true
                            }

                            ClippedProgressBar {
                                Layout.fillWidth: true
                                value: 0.7
                            }

                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 30

                                ClippedFilledCircularProgress {
                                    value: 0.6
                                    implicitSize: 60
                                }

                                ClippedFilledCircularProgress {
                                    value: 0.8
                                    implicitSize: 60
                                }

                            }

                        }
                        // Section: Special Components

                        StyledText {
                            text: "Special Components"
                            font.pixelSize: 20
                            font.weight: Font.Bold
                            Layout.topMargin: 20
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 15

                            KeyboardKey {
                                key: "Ctrl"
                            }

                            KeyboardKey {
                                key: "Alt"
                            }

                            KeyboardKey {
                                key: "Del"
                            }

                        }

                        WavyLine {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 20
                        }

                        LightDarkPreferenceButton {
                            Layout.alignment: Qt.AlignHCenter
                            dark: false
                        }

                        Revealer {
                            Layout.fillWidth: true
                            reveal: true

                            RowLayout {
                                spacing: 10

                                MaterialSymbol {
                                    text: "check_circle"
                                    iconSize: 24
                                    fill: 1
                                }

                                StyledText {
                                    text: "This content is revealed with animation!"
                                }

                            }

                        }
                        // Section: Text Input Variants

                        StyledText {
                            text: "Text Input Variants"
                            font.pixelSize: 20
                            font.weight: Font.Bold
                            Layout.topMargin: 20
                        }

                        StyledTextInput {
                            Layout.fillWidth: true
                            text: "StyledTextInput component"
                        }

                        StyledTextArea {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 80
                            text: "StyledTextArea component\nMultiline text support"
                        }
                        // Bottom spacing

                        Item {
                            Layout.preferredHeight: 40
                        }

                    }

                }

            }

            MouseArea {
                anchors.fill: parent
                z: -1
                onClicked: {
                    Qt.quit();
                }
            }

        }

    }

}
