import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// floating window of questionable life choices
FloatingWindow {
    id: root

    property string accentColor: "#ff6b9d"
    property string bgColor: "#111111"
    property string surfaceColor: "#1e1e1e"
    property string borderColor: "#2a2a2a"

    readonly property string home: Quickshell.env("HOME")
    readonly property string wallpaperDir: home + "/.config/quickshell/lazerbar/wallpapers"

    // your wallpaper is about to be replaced (sorry not sorry)
    signal wallpaperApplyRequested(string path)

    visible: false
    width: 800
    height: 600
    title: "Wallpaper Selector"
    color: root.bgColor

    // the world's most basic file registry
    ListModel { id: wallpaperModel }

    // hyprland said "what shortcut?" so we tell it
    GlobalShortcut {
        name: "wallpaperSelectorToggle"
        description: "Toggle wallpaper selector"
        onPressed: root.show()
    }

    // ls but with emotional support
    Process {
        id: lister
        running: false
        command: ["ls", "-1", root.wallpaperDir]
        stdout: StdioCollector {
            onStreamFinished: {
                wallpaperModel.clear()
                var lines = text.trim().split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var name = lines[i].trim()
                    if (name === "") continue
                    wallpaperModel.append({ name: name, path: root.wallpaperDir + "/" + name })
                }
            }
        }
        // force the grid to care about its existence
        onRunningChanged: {
            if (!lister.running) grid.forceActiveFocus()
        }
    }

    // reveal thyself
    function show() {
        root.visible = true
        lister.running = true
        Qt.callLater(() => grid.forceActiveFocus())
    }

    // back to the void
    function hide() {
        root.visible = false
    }

    // the moment of truth
    function applyCurrent() {
        if (grid.currentIndex >= 0 && grid.currentIndex < wallpaperModel.count) {
            var item = wallpaperModel.get(grid.currentIndex)
            root.wallpaperApplyRequested(item.path)
            root.hide()
        }
    }

    // the container for your containment needs
    Rectangle {
        anchors.fill: parent
        color: root.bgColor

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // header - where the cool buttons live
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                spacing: 8

                Text {
                    text: "Wallpapers  (" + wallpaperModel.count + ")"
                    color: "#ffffff"
                    font.family: "Torus"
                    font.pixelSize: 14
                    font.bold: true
                }

                Item { Layout.fillWidth: true }

                // refresh because sometimes you need to pretend you're doing something
                Rectangle {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    radius: 4
                    color: root.accentColor
                    Text {
                        anchors.centerIn: parent
                        text: "\u21BB"
                        color: "#181818"
                        font.pixelSize: 14
                        font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: lister.running = true
                    }
                }

                // get me out of here
                Rectangle {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    radius: 4
                    color: root.surfaceColor
                    Text {
                        anchors.centerIn: parent
                        text: "\u2715"
                        color: "#ffffff"
                        font.pixelSize: 12
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.hide()
                    }
                }
            }

            // grid - look at all those pixels
            GridView {
                id: grid
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                cellWidth: 160
                cellHeight: 140
                focus: true
                model: wallpaperModel
                currentIndex: -1
                keyNavigationWraps: true

                // each one is a potential new identity
                delegate: Item {
                    width: grid.cellWidth
                    height: grid.cellHeight

                    Rectangle {
                        anchors {
                            fill: parent
                            margins: 4
                        }
                        radius: 6
                        color: grid.currentIndex === index ? root.accentColor : root.surfaceColor
                        border.color: grid.currentIndex === index ? root.accentColor : root.borderColor
                        border.width: grid.currentIndex === index ? 2 : 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 4

                            // tiny window into another world
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 4
                                color: "#000000"
                                clip: true

                                Image {
                                    anchors.fill: parent
                                    source: "file://" + model.path
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    sourceSize.width: 160
                                    sourceSize.height: 120
                                }
                            }

                            // the filename you'll forget in 5 seconds
                            Text {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 16
                                text: model.name
                                color: grid.currentIndex === index ? "#181818" : "#cccccc"
                                font.family: "Torus"
                                font.pixelSize: 10
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }
                        }

                        // click and pray
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                grid.currentIndex = index
                                root.applyCurrent()
                            }
                        }
                    }
                }

                // keyboard warriors welcome
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.applyCurrent()
                        event.accepted = true
                    } else if (event.key === Qt.Key_Escape) {
                        root.hide()
                        event.accepted = true
                    }
                }
            }
        }
    }
}
