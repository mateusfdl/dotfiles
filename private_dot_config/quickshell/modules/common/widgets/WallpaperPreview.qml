import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Qt.labs.folderlistmodel
import Qt5Compat.GraphicalEffects
import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: root

    property string wallpaperPath: "/home/matheus/Pictures/wallpapers"
    property int currentIndex: 0
    property string currentWallpaper: ""
    property string wallpaperToApply: ""

    implicitWidth: 1900
    implicitHeight: 620
    color: Appearance.colors.colLayer1
    border.color: Appearance.m3colors.m3borderSecondary
    border.width: 1
    topLeftRadius: 12
    topRightRadius: 12
    bottomLeftRadius: 0
    bottomRightRadius: 0

    layer.enabled: true
    layer.effect: DropShadow {
        horizontalOffset: 0
        verticalOffset: 10
        radius: 30
        samples: 31
        color: Appearance.m3colors.m3shadowColor
        opacity: 0.7
    }

    function navigateLeft() {
        if (currentIndex > 0) {
            currentIndex--
            galleryView.currentIndex = currentIndex
            updateCurrentWallpaper()
        }
    }

    function navigateRight() {
        if (currentIndex < folderModel.count - 1) {
            currentIndex++
            galleryView.currentIndex = currentIndex
            updateCurrentWallpaper()
        }
    }

    function applyCurrentWallpaper() {
        if (currentWallpaper.length > 0) {
            applyWallpaper(currentWallpaper)
        }
    }

    // Wallpaper extensions to filter
    readonly property list<string> extensions: [
        "*.jpg", "*.jpeg", "*.png", "*.webp", "*.avif", "*.bmp"
    ]

    FolderListModel {
        id: folderModel
        folder: "file://" + wallpaperPath
        nameFilters: searchField.text.length > 0
            ? extensions.map(ext => "*" + searchField.text + ext)
            : extensions
        showDirs: false
        showDotAndDotDot: false
        showOnlyReadable: true
        sortField: FolderListModel.Name

        onCountChanged: {
            if (count > 0 && currentIndex >= count) {
                currentIndex = count - 1
            }
            if (count > 0 && currentIndex < 0) {
                currentIndex = 0
            }
            updateCurrentWallpaper()
        }
    }

    function updateCurrentWallpaper() {
        if (folderModel.count > 0 && currentIndex >= 0 && currentIndex < folderModel.count) {
            currentWallpaper = folderModel.get(currentIndex, "filePath")
        }
    }

    function applyWallpaper(wallpaperPath) {
          wallpaperToApply = wallpaperPath
          wallpaperProcess.running = true
          copyWallpaperProcess.running = true
    }

    Process {
        id: wallpaperProcess
        command: [
            "swww", "img", root.wallpaperToApply,
            "--transition-bezier", ".43,1.19,1,.4",
            "--transition-fps", "144",
            "--transition-type", "grow",
            "--transition-pos", "0.925,0.977",
            "--transition-duration", "1"
        ]
    }

    Process {
      id: copyWallpaperProcess
      command: [
            "bash", "-c",
            `cp -f "${root.wallpaperToApply}" ~/.cache/current_wallpaper && \
            sudo cp -f "${root.wallpaperToApply}" /usr/share/sddm/themes/my-sddm/Backgrounds/default`
          ]
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 22
        spacing: 20

        // Gallery view
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: galleryView
                anchors.fill: parent
                orientation: ListView.Horizontal
                spacing: 20
                clip: true

                model: folderModel
                currentIndex: root.currentIndex

                highlightFollowsCurrentItem: true
                highlightMoveDuration: 300
                highlightMoveVelocity: -1

                preferredHighlightBegin: width / 2 - 290
                preferredHighlightEnd: width / 2 + 290
                highlightRangeMode: ListView.ApplyRange

                delegate: Item {
                    id: delegateItem
                    required property string fileName
                    required property string filePath
                    required property int index

                    width: 580
                    height: galleryView.height

                    readonly property bool isCurrent: ListView.isCurrentItem

                    scale: isCurrent ? 1.0 : 0.85
                    opacity: isCurrent ? 1.0 : 0.6

                    Behavior on scale {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutCubic
                        }
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 12
                        width: parent.width

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 560
                            height: 315 // 16:9 aspect ratio
                            color: Appearance.colors.colLayer2
                            radius: 8

                            border.width: delegateItem.isCurrent ? 2 : 0
                            border.color: Appearance.m3colors.m3accentPrimary

                            Image {
                                id: thumbnailImage
                                anchors.fill: parent
                                anchors.margins: 2
                                source: "file://" + delegateItem.filePath
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                smooth: true
                                cache: true

                                layer.enabled: true
                                layer.effect: OpacityMask {
                                    maskSource: Rectangle {
                                        width: thumbnailImage.width
                                        height: thumbnailImage.height
                                        radius: 6
                                    }
                                }
                            }

                            Rectangle {
                                anchors.centerIn: parent
                                width: 40
                                height: 40
                                radius: 20
                                color: Appearance.colors.colLayer1
                                visible: thumbnailImage.status === Image.Loading

                                StyledText {
                                    anchors.centerIn: parent
                                    text: "..."
                                    color: Appearance.m3colors.m3primaryText
                                    font.pixelSize: 16
                                }
                            }
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.maximumWidth: 560
                            text: delegateItem.fileName
                            color: delegateItem.isCurrent
                                ? Appearance.m3colors.m3primaryText
                                : Appearance.m3colors.m3secondaryText
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideMiddle

                            Behavior on color {
                                ColorAnimation { duration: 300 }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.currentIndex = delegateItem.index
                            root.updateCurrentWallpaper()
                        }
                    }
                }

                onCurrentIndexChanged: {
                    root.currentIndex = currentIndex
                    root.updateCurrentWallpaper()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            color: Appearance.colors.colLayer2
            radius: 8
            border.width: 1
            border.color: searchField.activeFocus
                ? Appearance.m3colors.m3accentPrimary
                : Appearance.m3colors.m3borderSecondary

            Behavior on border.color {
                ColorAnimation { duration: 200 }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                StyledText {
                    text: ">"
                    color: Appearance.m3colors.m3accentPrimary
                    font.pixelSize: 16
                    font.family: Appearance.font.family.codeFont
                    font.bold: true
                }

                TextField {
                    id: searchField
                    Layout.fillWidth: true
                    focus: true

                    placeholderText: "wallpaper"
                    placeholderTextColor: Appearance.m3colors.m3secondaryText
                    color: Appearance.m3colors.m3primaryText
                    selectedTextColor: Appearance.m3colors.m3selectionText
                    selectionColor: Appearance.m3colors.m3selectionBackground
                    font.pixelSize: 14
                    font.family: Appearance.font.family.uiFont

                    background: Rectangle {
                        color: "transparent"
                    }

                    selectByMouse: true

                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Left || event.key === Qt.Key_Right) {
                            event.accepted = false
                        }
                    }
                }

                StyledText {
                    visible: searchField.text.length > 0
                    text: "×"
                    color: Appearance.m3colors.m3secondaryText
                    font.pixelSize: 20

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            searchField.text = ""
                            searchField.focus = true
                        }
                    }
                }
            }
        }

    }

    Component.onCompleted: {
        updateCurrentWallpaper()
    }
}
