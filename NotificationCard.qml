import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Hyprland

Item {
    id: root
    property var notificationObject
    property bool autoDismiss: true
    property int popupDuration: 5
    property bool enableDrag: true
    property bool clickDismisses: true
    property var onDismissed: null
    property string fallbackSummary: ""
    property string fallbackBody: ""
    property string fallbackAppName: ""
    property string fallbackImage: ""
    property string fallbackDesktopEntry: ""
    property string bgColor: "#1e1e24"
    property string surfaceColor: "#2a2a32"
    property string borderColor: "#3d3d43"
    property string borderHoverColor: "#5d5d63"


    width: 400

    // compact - because notifications shouldn't be novels
    height: Math.min(content.implicitHeight + 24, 160)

    Rectangle {
        id: container
        width: parent.width
        height: parent.height

        radius: 12
        color: root.bgColor
        border.color: mainMouse.containsMouse ? root.borderHoverColor : root.borderColor
        border.width: 1

        x: 0
        opacity: 0

        Component.onCompleted: entranceAnim.start()

        ParallelAnimation {
            id: entranceAnim
            NumberAnimation { target: container; property: "opacity"; from: 0; to: 1; duration: 250 }
            NumberAnimation { target: container; property: "x"; from: 40; to: 0; duration: 400; easing.type: Easing.OutBack }
        }

        ParallelAnimation {
            id: exitAnim
            NumberAnimation { target: container; property: "opacity"; to: 0; duration: 200 }
            NumberAnimation { target: container; property: "x"; to: 200; duration: 200; easing.type: Easing.InQuad }

            onFinished: {
                if (onDismissed) {
                    onDismissed()
                } else if (notificationObject) {
                    try { notificationObject.tracked = false } catch(e) {}
                    try { notificationObject.dismiss() } catch(e) {}
                }
            }
        }

        MouseArea {
            id: mainMouse
            anchors.fill: parent
            hoverEnabled: true

            drag.target: root.enableDrag ? container : null
            drag.axis: Drag.XAxis
            drag.minimumX: 0
            drag.maximumX: 1000

            onReleased: {
                if (container.x > 120)
                    exitAnim.start()
                else
                    backAnim.start()
            }

            function focusAppWindow(name) {
                if (!name || typeof Hyprland === 'undefined') return false;
                Hyprland.dispatch("focuswindow class:" + name.replace(/\.desktop$/, ''));
                return true;
            }

            onClicked: {
                if (!notificationObject) return

                var appName = notificationObject.desktopEntry || notificationObject.appName;

                // workspace teleport - beaming you there now
                if (appName) focusAppWindow(appName);

                // rise from the dead, dear application
                if (notificationObject.desktopEntry) {
                    Quickshell.execDetached({
                        command: ["gtk-launch", notificationObject.desktopEntry]
                    })

                } else if (notificationObject.appName) {
                    Quickshell.execDetached({
                        command: ["gtk-launch", notificationObject.appName]
                    })

                } else if (typeof notificationObject.invokeDefaultAction === "function") {
                    notificationObject.invokeDefaultAction()

                } else {
                    let actions = notificationObject.actions
                    let defaultFound = false

                    if (actions) {
                        for (let i = 0; i < actions.length; i++) {
                            let action = actions[i]
                            if (action && action.id === "default") {
                                action.invoke()
                                defaultFound = true
                                break
                            }
                        }
                    }

                    if (!defaultFound)
                        notificationObject.activate()
                }

                if (root.clickDismisses) exitAnim.start()
            }
        }

        NumberAnimation {
            id: backAnim
            target: container
            property: "x"
            to: 0
            duration: 200
            easing.type: Easing.OutQuad
        }

        // =========================
        // content - the meat and potatoes
        // =========================
        RowLayout {
            id: content
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            Rectangle {
                Layout.preferredWidth: 48
                Layout.preferredHeight: 48
                color: root.surfaceColor
                radius: 8

                Image {
                    id: notifIcon
                    anchors.centerIn: parent
                    width: 32
                    height: 32
                    fillMode: Image.PreserveAspectFit
                    source: notificationObject?.image ?? fallbackImage
                    asynchronous: true
                    sourceSize: Qt.size(64, 64)

                    property bool loadFailed: false
                    onStatusChanged: {
                        if (status === Image.Error) loadFailed = true
                    }
                    onSourceChanged: loadFailed = false
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 32
                    height: 32
                    radius: 6
                    color: root.bgColor
                    visible: notifIcon.loadFailed

                    Text {
                        anchors.centerIn: parent
                        text: {
                            var name = notificationObject?.appName ?? fallbackAppName ?? "?"
                            return name.charAt(0).toUpperCase()
                        }
                        color: "#888888"
                        font.family: "Torus"
                        font.pixelSize: 16
                        font.bold: true
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    Layout.fillWidth: true
                    text: notificationObject?.summary ?? fallbackSummary
                    color: "#ffffff"
                    font.family: "Torus"
                    font.bold: true
                    font.pixelSize: 14
                    wrapMode: Text.Wrap
                    maximumLineCount: expanded ? 999 : 2
                    elide: Text.ElideRight
                    clip: true

                    property bool expanded: false
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: parent.expanded = !parent.expanded
                    }
                }

                // =========================
                // body - read it or don't, i'm not your mom
                // =========================
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(bodyFlick.contentHeight, 80)

                    clip: true

                    Flickable {
                        id: bodyFlick
                        anchors.fill: parent

                        contentWidth: width
                        contentHeight: bodyText.implicitHeight
                        boundsBehavior: Flickable.StopAtBounds

                        Text {
                            id: bodyText
                            width: parent.width
                            text: notificationObject?.body ?? fallbackBody
                            color: "#888888"
                            font.family: "Torus"
                            font.pixelSize: 13
                            wrapMode: Text.Wrap
                        }
                    }

                    // =========================
                    // fade - dramatic exit stage left
                    // =========================
                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 18
                        z: 10

                        visible: bodyFlick.contentHeight > bodyFlick.height
                                 && bodyFlick.contentY < bodyFlick.contentHeight - bodyFlick.height - 1

                        opacity: visible ? 1.0 : 0.0

                        Behavior on opacity {
                            NumberAnimation { duration: 120 }
                        }

                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 1.0; color: root.bgColor }
                        }
                    }
                }
            }
        }

        // close - vanish, begone, avaunt
        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 6

            width: 22
            height: 22
            radius: 11
            color: closeMouse.containsMouse ? "#ff5580" : "#c31c44"
            
            Text {
                anchors.centerIn: parent
                text: "✕"
                color: "#ffffff"
                font.pixelSize: 12
            }

            MouseArea {
                id: closeMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: exitAnim.start()
            }
        }
    }

    Timer {
        id: autoDismissTimer
        interval: root.popupDuration * 1000
        running: root.autoDismiss && !mainMouse.containsMouse && container.x === 0
        onTriggered: exitAnim.start()
    }
}
