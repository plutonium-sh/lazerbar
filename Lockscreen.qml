import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Pam
import Quickshell.Services.UPower

Rectangle {
    id: lockRoot

    anchors.fill: parent
    color: bgColor

    property bool pamReady: false
    property string accentColor: "#ec8fbe"
    property string surfaceColor: "#1e1e24"
    property string bgColor: "#181818"
    property string borderColor: "#333333"

    property bool showDemoBattery: false
    signal unlocked

    Component.onCompleted: Qt.callLater(() => {
        passwordField.text = ""
        errorText.text = ""
        pamReady = false
        pam.user = Quickshell.env("USER")
        pam.config = "system-auth"
        pam.start()
    })

    MouseArea {
        anchors.fill: parent
        onPressed: (mouse) => mouse.accepted = true
    }

    Rectangle {
        id: outerRing
        anchors.centerIn: parent
        width: 600; height: 600; radius: 300
        color: "#22000000"
        opacity: 0.4
        scale: 0.95

        property bool expanded: false

        Timer {
            interval: 3000; running: true; repeat: true
            onTriggered: outerRing.expanded = !outerRing.expanded
        }

        states: [
            State {
                when: outerRing.expanded
                PropertyChanges { outerRing { scale: 1.05; opacity: 0.5 } }
            },
            State {
                when: !outerRing.expanded
                PropertyChanges { outerRing { scale: 0.85; opacity: 0.25 } }
            }
        ]
        transitions: [
            Transition {
                NumberAnimation { properties: "scale,opacity"; duration: 3000; easing.type: Easing.InOutSine }
            }
        ]
    }

    Rectangle {
        id: innerRing
        anchors.centerIn: parent
        width: 400; height: 400; radius: 200
        color: lockRoot.accentColor
        opacity: 0.12
        scale: 0.9

        property bool expanded: false

        Timer {
            interval: 4000; running: true; repeat: true
            onTriggered: innerRing.expanded = !innerRing.expanded
        }

        states: [
            State {
                when: innerRing.expanded
                PropertyChanges { innerRing { scale: 1.1; opacity: 0.2 } }
            },
            State {
                when: !innerRing.expanded
                PropertyChanges { innerRing { scale: 0.8; opacity: 0.08 } }
            }
        ]
        transitions: [
            Transition {
                NumberAnimation { properties: "scale,opacity"; duration: 4000; easing.type: Easing.InOutSine }
            }
        ]
    }

    Rectangle {
        anchors.left: parent.left; anchors.leftMargin: 60
        anchors.top: parent.top; anchors.topMargin: 60
        width: 60; height: 1
        color: accentColor
        opacity: 0.3
    }
    Rectangle {
        anchors.left: parent.left; anchors.leftMargin: 60
        anchors.top: parent.top; anchors.topMargin: 60
        width: 1; height: 60
        color: accentColor
        opacity: 0.3
    }
    Rectangle {
        anchors.right: parent.right; anchors.rightMargin: 60
        anchors.top: parent.top; anchors.topMargin: 60
        width: 60; height: 1
        color: accentColor
        opacity: 0.3
    }
    Rectangle {
        anchors.right: parent.right; anchors.rightMargin: 60
        anchors.top: parent.top; anchors.topMargin: 60
        width: 1; height: 60
        color: accentColor
        opacity: 0.3
    }
    Rectangle {
        anchors.left: parent.left; anchors.leftMargin: 60
        anchors.bottom: parent.bottom; anchors.bottomMargin: 60
        width: 60; height: 1
        color: accentColor
        opacity: 0.3
    }
    Rectangle {
        anchors.left: parent.left; anchors.leftMargin: 60
        anchors.bottom: parent.bottom; anchors.bottomMargin: 60
        width: 1; height: 60
        color: accentColor
        opacity: 0.3
    }
    Rectangle {
        anchors.right: parent.right; anchors.rightMargin: 60
        anchors.bottom: parent.bottom; anchors.bottomMargin: 60
        width: 60; height: 1
        color: accentColor
        opacity: 0.3
    }
    Rectangle {
        anchors.right: parent.right; anchors.rightMargin: 60
        anchors.bottom: parent.bottom; anchors.bottomMargin: 60
        width: 1; height: 60
        color: accentColor
        opacity: 0.3
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: Qt.formatDateTime(clock.date, "h:mm AP")
            font.pixelSize: 76
            font.family: "Torus"
            color: "#ffffff"
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            text: Qt.formatDateTime(clock.date, "dddd, MMMM d")
            font.pixelSize: 16
            font.family: "Torus"
            color: "#888888"
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 40
        }

        Rectangle {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 2
            radius: 1
            color: accentColor
            opacity: 0.6
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 32
        }

        Rectangle {
            Layout.preferredWidth: 280
            Layout.preferredHeight: 48
            radius: 10
            color: surfaceColor
            Layout.alignment: Qt.AlignHCenter
            border.width: 1
            border.color: passwordField.activeFocus ? accentColor : borderColor

            Behavior on border.color { ColorAnimation { duration: 150 } }

            TextField {
                id: passwordField
                anchors.fill: parent
                anchors.margins: 1
                background: null
                echoMode: TextInput.Password
                placeholderText: "password"
                placeholderTextColor: "#888888"
                color: "#ffffff"
                font.family: "Torus"
                font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: TextInput.AlignVCenter

                onAccepted: {
                    if (lockRoot.pamReady && text !== "") {
                        lockRoot.pamReady = false
                        pam.respond(text)
                    }
                }
            }
        }

        Text {
            id: errorText
            text: ""
            color: "#c31c44"
            font.pixelSize: 12
            font.family: "Torus"
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 8
        }
    }

    Item {
        id: batteryStatus
        visible: false
        property var batt: UPower.displayDevice
        property bool hasReal: UPower && UPower.devices && UPower.devices.count > 0
        property int mockPct: 67
        property bool mockCharging: true
        property int pct: hasReal ? Math.round(batt.percentage * 100) : mockPct
        property bool charging: hasReal ? (batt.state === UPowerDeviceState.Charging || batt.state === UPowerDeviceState.FullyCharged) : mockCharging

        Timer {
            interval: 3000
            running: !batteryStatus.hasReal && lockRoot.showDemoBattery
            repeat: true
            onTriggered: {
                batteryStatus.mockCharging = !batteryStatus.mockCharging
                if (batteryStatus.mockCharging)
                    batteryStatus.mockPct = Math.min(100, batteryStatus.mockPct + 5)
                else
                    batteryStatus.mockPct = Math.max(5, batteryStatus.mockPct - 3)
            }
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 48
        text: batteryStatus.charging ? "\u26A1 " + batteryStatus.pct + "%" : "\uD83D\uDD0B " + batteryStatus.pct + "%"
        color: batteryStatus.pct < 20 ? "#c31c44" : "#888888"
        font.family: "Torus"
        font.pixelSize: 14
        visible: showDemoBattery
    }

    PamContext {
        id: pam

        onCompleted: (result) => {
            if (result === PamResult.Success) {
                pam.abort()
                unlocked()
            } else {
                errorText.text = "wrong password"
                passwordField.text = ""
                Qt.callLater(() => {
                    pam.user = Quickshell.env("USER")
                    pam.config = "system-auth"
                    pam.start()
                })
            }
        }

        onError: (err) => {
            errorText.text = "auth error"
        }

        onPamMessage: {
            if (pam.responseRequired) {
                lockRoot.pamReady = true
                passwordField.forceActiveFocus()
            }
            if (pam.messageIsError) {
                errorText.text = pam.message
            }
        }
    }
}
