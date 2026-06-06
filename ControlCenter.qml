import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Widgets
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Networking


Rectangle {
    id: ccContainer

    property var notifModel: null
    property bool autoDismiss: true
    property string accentColor: "#ec8fbe"
    property string bgColor: "#181818"
    property string surfaceColor: "#1e1e24"
    property string borderColor: "#333333"

    property bool showDemoBattery: false
    property bool showWeather: true
    property bool wifiEnabled: true
    property bool useFahrenheit: false
    property int pomodoroWorkDuration: 25
    property int pomodoroBreakDuration: 5
    signal lockRequested
    signal exitConfirmRequested(string label, string cmd)
    property bool hasRealBattery: {
        if (!UPower || !UPower.devices) return false;
        var count = UPower.devices.count;
        for (var i = 0; i < count; i++) {
            var d = UPower.devices.get(i);
            if (d && d.isLaptopBattery && d.isPresent) return true;
        }
        return false;
    }
    property bool showBatterySection: showDemoBattery || hasRealBattery
    property bool panelVisible: true

    // --- calendar math - pray it works ---
    property date currentDate: new Date()
    property int year: currentDate.getFullYear()
    property int month: currentDate.getMonth()

    // 0 = sunday (the day of existential dread), 1 = monday (the sequel)
    property int firstDay: new Date(year, month, 1).getDay()

    // auto-handles leap years - february 29th believers unite
    property int daysInMonth: new Date(year, month + 1, 0).getDate()

    property var ccSections: [
        { name: "dashboard", icon: "collections.png" },
        { name: "clock", icon: "clock.png" },
        { name: "system", icon: "user-interface.png" }
    ]

    property int activeCategory: 0

    width: 380
    height: 750

    color: ccContainer.bgColor
    border.color: ccContainer.borderColor
    border.width: 3
    radius: 12

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // =========================================================
        // sidebar - pick your poison
        // =========================================================

        Rectangle {
            Layout.preferredWidth: 48
            Layout.fillHeight: true
            color: ccContainer.bgColor
            radius: 12

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 14
                spacing: 2

                Repeater {
                    model: ccContainer.ccSections

                    delegate: Item {
                        required property var modelData
                        required property int index

                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 40

                        property bool isActive: index === ccContainer.activeCategory

                        Rectangle {
                            anchors.fill: parent
                            anchors.leftMargin: 4
                            anchors.rightMargin: 4
                            radius: 8
                            color: mouseCat.containsMouse ? "#18ffffff" : "transparent"
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Image {
                                anchors.centerIn: parent
                                width: 24
                                height: 24
                                source: `file://${Quickshell.env("HOME")}/.config/quickshell/lazerbar/assets/${modelData.icon}`
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                mipmap: true
                            }

                            MouseArea {
                                id: mouseCat
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ccContainer.activeCategory = index
                            }
                        }

                        Rectangle {
                            width: 3
                            height: 16
                            radius: 1.5
                            color: ccContainer.accentColor
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            opacity: isActive ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }

        // =========================================================
        // divider
        // =========================================================

        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            color: ccContainer.borderColor
        }

        // =========================================================
        // content
        // =========================================================

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // =====================================================
            // dashboard - all your widgets in one place
            // =====================================================

            Item {
                visible: ccContainer.activeCategory === 0
                anchors.fill: parent
                anchors.margins: 20

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 20

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 15

                        Text {
                            text: Qt.formatDateTime(ccContainer.currentDate, "MMMM yyyy").toLowerCase()
                            color: ccContainer.accentColor
                            font.family: "Torus"
                            font.pixelSize: 18
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: calendarGrid.implicitHeight

                            GridLayout {
                                id: calendarGrid
                                anchors.horizontalCenter: parent.horizontalCenter
                                columns: 7
                                columnSpacing: 10
                                rowSpacing: 5

                                Repeater {
                                    model: ["s", "m", "t", "w", "t", "f", "s"]
                                    delegate: Text {
                                        text: modelData
                                        color: "#888888"
                                        font.family: "Torus"
                                        font.pixelSize: 12
                                        horizontalAlignment: Text.AlignHCenter
                                        width: 30
                                        Layout.preferredWidth: 30
                                    }
                                }

                                Repeater {
                                    model: ccContainer.firstDay + ccContainer.daysInMonth
                                    delegate: Rectangle {
                                        required property int index
                                        property int dayNumber: index - ccContainer.firstDay + 1
                                        property bool validDay: dayNumber > 0 && dayNumber <= ccContainer.daysInMonth
                                        property bool isToday: validDay && dayNumber === ccContainer.currentDate.getDate()
                                        width: 30
                                        height: 30
                                        radius: 4
                                        color: isToday ? ccContainer.accentColor : "transparent"
                                        Text {
                                            anchors.centerIn: parent
                                            text: validDay ? dayNumber : ""
                                            color: isToday ? "#ffffff" : "#888888"
                                            font.family: "Torus"
                                            font.pixelSize: 12
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: ccContainer.borderColor
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        visible: ccContainer.showWeather

                        RowLayout {
                            anchors.fill: parent
                            spacing: 8

                            Text {
                                text: weatherSection.weatherIcon
                                font.pixelSize: 20
                                color: "#ffffff"
                                Layout.alignment: Qt.AlignVCenter
                            }
                            Text {
                                text: (weatherSection.loaded ? (ccContainer.useFahrenheit ? weatherSection.rawTempF : weatherSection.rawTempC) : "--") + "\u00B0"
                                font.family: "Torus"
                                font.pixelSize: 16
                                font.bold: true
                                color: ccContainer.accentColor
                                Layout.alignment: Qt.AlignVCenter
                            }
                            Text {
                                text: weatherSection.condition
                                font.family: "Torus"
                                font.pixelSize: 12
                                color: "#888888"
                                Layout.alignment: Qt.AlignVCenter
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text {
                                text: weatherSection.loaded ? "" : "\u23F3"
                                font.pixelSize: 12
                                color: "#888888"
                                Layout.alignment: Qt.AlignVCenter
                                visible: !weatherSection.loaded
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: ccContainer.borderColor
                        visible: ccContainer.showWeather
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        visible: ccContainer.showBatterySection

                        RowLayout {
                            anchors.fill: parent
                            spacing: 15

                            Item {
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 20
                                Layout.alignment: Qt.AlignVCenter
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 3
                                    color: ccContainer.surfaceColor
                                    border.width: 1
                                    border.color: batteryStatus.charging ? "#01EB9D" : (batteryStatus.pct < 20 ? "#c31c44" : "#666666")
                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        anchors.margins: 2
                                        width: (parent.width - 4) * (batteryStatus.pct / 100)
                                        radius: 2
                                        color: {
                                            if (batteryStatus.charging) return "#01EB9D";
                                            if (batteryStatus.pct < 20) return "#c31c44";
                                            if (batteryStatus.pct < 50) return "#ffcc44";
                                            return "#01EB9D";
                                        }
                                    }
                                }
                                Rectangle {
                                    x: parent.width + 2
                                    y: parent.height / 2 - 3
                                    width: 4; height: 6; radius: 1
                                    color: batteryStatus.charging ? "#01EB9D" : "#666666"
                                }
                            }
                            Text {
                                text: batteryStatus.pct + "%"
                                font.family: "Torus"
                                font.pixelSize: 18
                                font.bold: true
                                color: {
                                    if (batteryStatus.charging) return "#01EB9D";
                                    if (batteryStatus.pct < 20) return "#c31c44";
                                    if (batteryStatus.pct < 50) return "#ffcc44";
                                    return "#ffffff";
                                }
                                Layout.alignment: Qt.AlignVCenter
                            }
                            Text {
                                text: {
                                    if (!ccContainer.hasRealBattery) return "demo mode";
                                    if (batteryStatus.charging) return "charging";
                                    return "on battery";
                                }
                                font.family: "Torus"
                                font.pixelSize: 12
                                color: "#888888"
                                Layout.alignment: Qt.AlignVCenter
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: {
                                    if (!ccContainer.hasRealBattery) return "";
                                    var b = batteryStatus.batt;
                                    var t = batteryStatus.charging ? b.timeToFull : b.timeToEmpty;
                                    if (t <= 0) return "";
                                    var h = Math.floor(t / 3600);
                                    var m = Math.floor((t % 3600) / 60);
                                    return (batteryStatus.charging ? "full in " : "") + h + "h " + m + "m";
                                }
                                font.family: "Torus"
                                font.pixelSize: 12
                                color: "#888888"
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: ccContainer.borderColor
                        visible: ccContainer.showBatterySection
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "notification history"
                            color: ccContainer.accentColor
                            font.family: "Torus"
                            font.pixelSize: 14
                            font.bold: true
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "clear all"
                            color: "#888888"
                            font.family: "Torus"
                            font.pixelSize: 12
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { if (ccContainer.notifModel) ccContainer.notifModel.clear() }
                            }
                        }
                    }

                    ListView {
                        id: historyList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: ccContainer.notifModel
                        spacing: 10
                        delegate: NotificationCard {
                            notificationObject: model.notifObj
                            fallbackSummary: model.summary ?? ""
                            fallbackBody: model.body ?? ""
                            fallbackAppName: model.appName ?? ""
                            fallbackImage: model.notifImage ?? ""
                            fallbackDesktopEntry: model.desktopEntry ?? ""
                            width: ListView.view.width
                            autoDismiss: false
                            enableDrag: false
                            clickDismisses: false
                            bgColor: ccContainer.bgColor
                            surfaceColor: ccContainer.surfaceColor
                            borderColor: ccContainer.borderColor
                            borderHoverColor: "#5d5d63"

                            Component.onCompleted: {
                                onDismissed = function() {
                                    ccContainer.notifModel.remove(index)
                                }
                            }
                        }
                        Text {
                            visible: historyList.count === 0
                            anchors.centerIn: parent
                            text: "no missed notifications"
                            color: "#888888"
                            font.family: "Torus"
                        }
                    }
                }
            }

            // =====================================================
            // clock - 🍅
            // =====================================================

            Item {
                visible: ccContainer.activeCategory === 1
                anchors.fill: parent
                anchors.margins: 20

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 12

                    Item { Layout.fillHeight: true }

                    Text {
                        text: "\uD83C\uDF45"
                        font.pixelSize: 48
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: pomodoroBackend.displayTime
                        font.family: "Torus"
                        font.pixelSize: 52
                        font.bold: true
                        color: pomodoroBackend.onBreak ? "#44dd88" : ccContainer.accentColor
                        Layout.alignment: Qt.AlignHCenter
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 16

                        Rectangle {
                            Layout.preferredWidth: 44
                            Layout.preferredHeight: 44
                            radius: 22
                            color: pomodoroBackend.running ? ccContainer.surfaceColor : ccContainer.accentColor

                            Text {
                                anchors.centerIn: parent
                                text: pomodoroBackend.running ? "\u23F8" : "\u25B6"
                                font.pixelSize: 20
                                color: "#ffffff"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (pomodoroBackend.running) pomodoroBackend.pause();
                                    else pomodoroBackend.start();
                                }
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 44
                            Layout.preferredHeight: 44
                            radius: 22
                            color: ccContainer.surfaceColor

                            Text {
                                anchors.centerIn: parent
                                text: "\u21BA"
                                font.pixelSize: 22
                                color: "#ffffff"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: pomodoroBackend.reset()
                            }
                        }
                    }

                    Text {
                        text: {
                            if (!pomodoroBackend.running && pomodoroBackend.remaining === ccContainer.pomodoroWorkDuration * 60) return "ready";
                            if (pomodoroBackend.onBreak) return "break time \u2615";
                            return "focus \u2728";
                        }
                        font.family: "Torus"
                        font.pixelSize: 12
                        color: "#888888"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 6
                        radius: 3
                        color: ccContainer.surfaceColor

                        Rectangle {
                            width: parent.width * pomodoroBackend.progress
                            height: parent.height
                            radius: 3
                            color: pomodoroBackend.onBreak ? "#44dd88" : ccContainer.accentColor
                            Behavior on width { NumberAnimation { duration: 300 } }
                        }
                    }

                    Text {
                        text: pomodoroBackend.completedPomodoros > 0 ? pomodoroBackend.completedPomodoros + " pomodoros completed" : ""
                        font.family: "Torus"
                        font.pixelSize: 11
                        color: "#888888"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Item { Layout.fillHeight: true }
                }
            }

            // =====================================================
            // system - workspaces and machine info
            // =====================================================

            Item {
                visible: ccContainer.activeCategory === 2
                anchors.fill: parent
                anchors.margins: 20

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 16

                    Flow {
                        Layout.fillWidth: true
                        spacing: 8

                        Repeater {
                            model: [
                                { label: "lock", icon: "\uD83D\uDD12", cmd: "" },
                                { label: "shot", icon: "\uD83D\uDCF7", cmd: "hyprshot -m region" },
                                { label: "logout", icon: "\uD83D\uDEAA", cmd: "hyprctl dispatch exit" },
                                { label: "shutdown", icon: "\u23F0", cmd: "systemctl poweroff" },
                                { label: "reboot", icon: "\uD83D\uDD04", cmd: "systemctl reboot" }
                            ]

                            delegate: Item {
                                required property var modelData
                                width: (parent.width - parent.spacing * 4) / 5
                                height: 52

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 8
                                    color: btnMouse.containsMouse ? Qt.alpha(ccContainer.accentColor, 0.2) : "transparent"
                                    border.width: 1
                                    border.color: btnMouse.containsMouse ? ccContainer.accentColor : ccContainer.borderColor
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    Behavior on border.color { ColorAnimation { duration: 150 } }

                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 4

                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: modelData.icon
                                            font.pixelSize: 18
                                        }

                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: modelData.label
                                            color: btnMouse.containsMouse ? ccContainer.accentColor : "#ffffff"
                                            font.family: "Torus"
                                            font.pixelSize: 9
                                            font.bold: btnMouse.containsMouse
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                        }
                                    }

                                    MouseArea {
                                        id: btnMouse
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        hoverEnabled: true
                                        onClicked: {
                                            if (modelData.label === "lock")
                                                ccContainer.lockRequested()
                                            else if (modelData.label === "logout" || modelData.label === "shutdown" || modelData.label === "reboot")
                                                ccContainer.exitConfirmRequested(modelData.label, modelData.cmd)
                                            else
                                                Quickshell.execDetached({ command: ["sh", "-c", modelData.cmd] })
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // brightness slider
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        visible: brightnessCtrl.available

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text { text: "brightness"; color: "#ffffff"; font.family: "Torus"; font.pixelSize: 13; Layout.fillWidth: true }
                            Item { Layout.fillWidth: true }
                            Text { text: brightnessCtrl.value + "%"; color: ccContainer.accentColor; font.family: "Torus"; font.pixelSize: 12; font.bold: true }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 24
                            radius: 4
                            color: "#2a2a32"
                            clip: true

                            Rectangle {
                                height: parent.height
                                width: parent.width * (brightnessCtrl.value / Math.max(1, brightnessCtrl.maxVal))
                                radius: 4
                                color: ccContainer.accentColor
                                Behavior on width { NumberAnimation { duration: 100 } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onPositionChanged: (mouse) => { if (pressed) { var ratio = Math.max(0, Math.min(1, mouse.x / width)); brightnessCtrl.setBrightness(ratio * brightnessCtrl.maxVal); } }
                                onPressed: (mouse) => { var ratio = Math.max(0, Math.min(1, mouse.x / width)); brightnessCtrl.setBrightness(ratio * brightnessCtrl.maxVal); }
                            }
                        }
                    }

                    // wi-fi
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: "wi-fi"
                                color: ccContainer.accentColor
                                font.family: "Torus"
                                font.pixelSize: 14
                                font.bold: true
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: wifiSection.scanning ? "scanning..." : "\u21BB"
                                color: wifiSection.scanning ? ccContainer.accentColor : "#888888"
                                font.family: "Torus"
                                font.pixelSize: 12
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: wifiSection.scan()
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: wifiSection.statusText
                            color: "#888888"
                            font.family: "Torus"
                            font.pixelSize: 10
                            visible: !wifiSection.wifiDevice
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.min(wifiColumn.height, 200)
                            visible: !!wifiSection.wifiDevice
                            clip: true

                            Flickable {
                                anchors.fill: parent
                                contentHeight: wifiColumn.height
                                interactive: contentHeight > height
                                clip: true

                                Column {
                                    id: wifiColumn
                                    width: parent.width
                                    spacing: 4

                                    Text {
                                        text: {
                                            var n = wifiSection.wifiNetworks;
                                            if (!n || n.values.length === 0) return "scanning...";
                                            return "";
                                        }
                                        color: "#888888"
                                        font.family: "Torus"
                                        font.pixelSize: 10
                                        visible: text !== ""
                                    }

                                    Repeater {
                                        model: wifiSection.wifiNetworks

                                        delegate: Column {
                                            id: netDelegate
                                            required property var modelData
                                            width: parent.width
                                            spacing: 4

                                            property bool showPassword: false

                                            Rectangle {
                                                width: parent.width
                                                height: 34
                                                radius: 6
                                                color: netMouse.containsMouse ? ccContainer.surfaceColor : "transparent"
                                                Behavior on color { ColorAnimation { duration: 120 } }

                                                RowLayout {
                                                    anchors.fill: parent
                                                    anchors.leftMargin: 8
                                                    anchors.rightMargin: 8
                                                    spacing: 8

                                                    Text {
                                                        Layout.preferredWidth: 24
                                                        Layout.alignment: Qt.AlignVCenter
                                                        text: Math.round((modelData.signalStrength || 0) * 100) + "%"
                                                        color: modelData.connected ? ccContainer.accentColor : "#888888"
                                                        font.family: "Torus"
                                                        font.pixelSize: 10
                                                    }

                                                    Text {
                                                        Layout.fillWidth: true
                                                        text: modelData.name || "(unknown)"
                                                        color: "#ffffff"
                                                        font.family: "Torus"
                                                        font.pixelSize: 12
                                                        elide: Text.ElideRight
                                                    }

                                                    Text {
                                                        text: {
                                                            if (!modelData.connected && modelData.known) return "saved";
                                                            return "";
                                                        }
                                                        color: "#888888"
                                                        font.family: "Torus"
                                                        font.pixelSize: 10
                                                        visible: text !== ""
                                                    }

                                                    Text {
                                                        text: "\uD83D\uDD12"
                                                        color: "#888888"
                                                        font.pixelSize: 11
                                                        visible: modelData.security !== undefined && modelData.security !== 0
                                                    }

                                                    Text {
                                                        text: "connected"
                                                        color: "#01EB9D"
                                                        font.family: "Torus"
                                                        font.pixelSize: 10
                                                        font.bold: true
                                                        visible: modelData.connected
                                                    }
                                                }

                                                MouseArea {
                                                    id: netMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        if (modelData.connected) {
                                                            modelData.disconnect();
                                                        } else if (modelData.known) {
                                                            modelData.connect();
                                                        } else if (modelData.security !== undefined && modelData.security !== 0) {
                                                            netDelegate.showPassword = !netDelegate.showPassword;
                                                        } else {
                                                            modelData.connect();
                                                        }
                                                    }
                                                }
                                            }

                                            Rectangle {
                                                id: passwordRow
                                                width: parent.width
                                                height: visible ? 36 : 0
                                                visible: netDelegate.showPassword
                                                radius: 6
                                                color: ccContainer.surfaceColor

                                                RowLayout {
                                                    anchors.fill: parent
                                                    anchors.margins: 6
                                                    spacing: 6

                                                    TextField {
                                                        id: pskField
                                                        Layout.fillWidth: true
                                                        Layout.preferredHeight: 24
                                                        background: Rectangle {
                                                            radius: 4
                                                            color: "#2a2a32"
                                                        }
                                                        leftPadding: 8
                                                        rightPadding: 8
                                                        verticalAlignment: TextInput.AlignVCenter
                                                        color: "#ffffff"
                                                        font.family: "Torus"
                                                        font.pixelSize: 11
                                                        echoMode: TextInput.Password
                                                        placeholderText: "password"
                                                        placeholderTextColor: "#888888"
                                                        onAccepted: {
                                                            if (pskField.text) {
                                                                modelData.connectWithPsk(pskField.text);
                                                                netDelegate.showPassword = false;
                                                                pskField.text = "";
                                                            }
                                                        }
                                                    }

                                                    Text {
                                                        text: "connect"
                                                        color: ccContainer.accentColor
                                                        font.family: "Torus"
                                                        font.pixelSize: 11
                                                        font.bold: true
                                                        MouseArea {
                                                            anchors.fill: parent
                                                            anchors.margins: -4
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: {
                                                                if (pskField.text) {
                                                                    modelData.connectWithPsk(pskField.text);
                                                                    netDelegate.showPassword = false;
                                                                    pskField.text = "";
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: ccContainer.borderColor
                    }

                    Text {
                        text: "system"
                        color: ccContainer.accentColor
                        font.family: "Torus"
                        font.pixelSize: 14
                        font.bold: true
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text {
                                text: "hostname"
                                color: "#888888"
                                font.family: "Torus"
                                font.pixelSize: 12
                                Layout.preferredWidth: 80
                            }
                            Text {
                                text: sysInfo.hostname
                                color: "#ffffff"
                                font.family: "Torus"
                                font.pixelSize: 12
                                font.bold: true
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text {
                                text: "os"
                                color: "#888888"
                                font.family: "Torus"
                                font.pixelSize: 12
                                Layout.preferredWidth: 80
                            }
                            Text {
                                text: sysInfo.os
                                color: "#ffffff"
                                font.family: "Torus"
                                font.pixelSize: 12
                                font.bold: true
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text {
                                text: "kernel"
                                color: "#888888"
                                font.family: "Torus"
                                font.pixelSize: 12
                                Layout.preferredWidth: 80
                            }
                            Text {
                                text: sysInfo.kernel
                                color: "#ffffff"
                                font.family: "Torus"
                                font.pixelSize: 12
                                font.bold: true
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text {
                                text: "uptime"
                                color: "#888888"
                                font.family: "Torus"
                                font.pixelSize: 12
                                Layout.preferredWidth: 80
                            }
                            Text {
                                text: sysInfo.displayUptime
                                color: "#ffffff"
                                font.family: "Torus"
                                font.pixelSize: 12
                                font.bold: true
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }
        }
    }

    // =========================================================
    // battery state - the quiet intern
    // =========================================================

    Item {
        id: batteryStatus
        visible: false
        property var batt: UPower.displayDevice
        property int mockPct: 67
        property bool mockCharging: true
        property int pct: ccContainer.hasRealBattery ? Math.round(batt.percentage * 100) : mockPct
        property bool charging: ccContainer.hasRealBattery ? (batt.state === UPowerDeviceState.Charging || batt.state === UPowerDeviceState.FullyCharged) : mockCharging

        Timer {
            interval: 3000
            running: !ccContainer.hasRealBattery && ccContainer.showDemoBattery
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

    // =========================================================
    // pomodoro backend - 🍅 shaped productivity
    // =========================================================

    Item {
        id: pomodoroBackend
        visible: false
        property int remaining: ccContainer.pomodoroWorkDuration * 60
        property bool running: false
        property bool onBreak: false
        property int completedPomodoros: 0

        property string displayTime: {
            var m = Math.floor(remaining / 60);
            var s = remaining % 60;
            return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
        }

        property real progress: {
            var total = (onBreak ? ccContainer.pomodoroBreakDuration : ccContainer.pomodoroWorkDuration) * 60;
            return total > 0 ? 1 - (remaining / total) : 0;
        }

        function start() { running = true; }
        function pause() { running = false; }
        function reset() {
            running = false;
            onBreak = false;
            remaining = ccContainer.pomodoroWorkDuration * 60;
        }

        Timer {
            interval: 1000
            running: pomodoroBackend.running
            repeat: true
            onTriggered: {
                pomodoroBackend.remaining--;
                if (pomodoroBackend.remaining <= 0) {
                    pomodoroBackend.running = false;
                    if (pomodoroBackend.onBreak) {
                        pomodoroBackend.onBreak = false;
                        pomodoroBackend.completedPomodoros++;
                        pomodoroBackend.remaining = ccContainer.pomodoroWorkDuration * 60;
                        notifyProc.command = ["notify-send", "--app-name=pomodoro", "break over", "time to focus!"];
                        notifyProc.running = true;
                    } else {
                        pomodoroBackend.onBreak = true;
                        pomodoroBackend.remaining = ccContainer.pomodoroBreakDuration * 60;
                        notifyProc.command = ["notify-send", "--app-name=pomodoro", "time's up", "take a break!"];
                        notifyProc.running = true;
                    }
                }
            }
        }

        Process {
            id: notifyProc
            running: false
        }
    }

    // =========================================================
    // weather backend - checking the sky from the shadows
    // =========================================================

    Item {
        id: weatherSection
        visible: false
        property string condition: "loading..."
        property string weatherIcon: "\u2601"
        property bool loaded: false
        property string rawTempC: "--"
        property string rawTempF: "--"

        Timer {
            interval: 600000
            running: true
            repeat: true
            onTriggered: {
                weatherFetchProc.running = false;
                weatherFetchProc.running = true;
            }
        }

        Process {
            id: weatherFetchProc
            running: false
            command: ["sh", "-c", "curl -s --max-time 5 wttr.in/?format=j1 > /tmp/lazerbar-weather.json"]
            onExited: (exitCode) => { weatherFile.reload(); }
            Component.onCompleted: running = true
        }

        FileView {
            id: weatherFile
            path: "/tmp/lazerbar-weather.json"
            onLoaded: {
                try {
                    var raw = text().trim();
                    if (!raw) return;
                    var json = JSON.parse(raw);
                    var cur = json.current_condition[0];
                    if (!cur) return;
                    var tempC = cur.temp_C;
                    var tempF = cur.temp_F;
                    weatherSection.rawTempC = tempC;
                    weatherSection.rawTempF = tempF;
                    var desc = cur.weatherDesc[0].value.toLowerCase();
                    weatherSection.condition = cur.weatherDesc[0].value;

                    if (desc.includes("sunny") || desc.includes("clear")) weatherSection.weatherIcon = "\u2600";
                    else if (desc.includes("partly cloudy")) weatherSection.weatherIcon = "\u26C5";
                    else if (desc.includes("cloudy") || desc.includes("overcast")) weatherSection.weatherIcon = "\u2601";
                    else if (desc.includes("thunder") || desc.includes("storm")) weatherSection.weatherIcon = "\u26C8";
                    else if (desc.includes("rain") || desc.includes("drizzle") || desc.includes("shower")) weatherSection.weatherIcon = "\uD83C\uDF27";
                    else if (desc.includes("snow") || desc.includes("sleet") || desc.includes("blizzard")) weatherSection.weatherIcon = "\u2744";
                    else if (desc.includes("fog") || desc.includes("mist") || desc.includes("haze")) weatherSection.weatherIcon = "\uD83C\uDF2B";
                    else weatherSection.weatherIcon = "\u2601";

                    weatherSection.loaded = true;
                } catch (e) {
                    weatherSection.condition = "offline";
                }
            }
        }
    }

    // =========================================================
    // brightness - ddcutil backend
    // =========================================================

    Item {
        id: brightnessCtrl
        visible: false
        property int value: 50
        property int maxVal: 100
        property bool available: false

        function refresh() {
            getBrightnessProc.running = false;
            getBrightnessProc.running = true;
        }

        function setBrightness(v) {
            v = Math.max(0, Math.min(maxVal, Math.round(v)));
            setBrightnessProc.command = ["ddcutil", "setvcp", "10", String(v)];
            setBrightnessProc.running = true;
            value = v;
        }

        Process {
            id: getBrightnessProc
            running: true
            command: ["sh", "-c", "ddcutil getvcp 10 2>/dev/null | head -1 > /tmp/lazerbar-brightness"]
            onExited: (code) => { if (code === 0) brightnessFile.reload(); }
        }

        FileView {
            id: brightnessFile
            path: "/tmp/lazerbar-brightness"
            onLoaded: {
                var raw = text().trim();
                var m = raw.match(/current value\s*=\s*(\d+)/i);
                var mm = raw.match(/max value\s*=\s*(\d+)/i);
                if (m && mm) {
                    brightnessCtrl.value = parseInt(m[1]);
                    brightnessCtrl.maxVal = parseInt(mm[1]);
                    brightnessCtrl.available = true;
                }
            }
        }

        Process { id: setBrightnessProc; running: false }

        Timer {
            interval: 5000
            running: ccContainer.panelVisible
            repeat: true
            onTriggered: brightnessCtrl.refresh()
        }
    }

    // =========================================================
    // wi-fi backend
    // =========================================================

    Item {
        id: wifiSection
        visible: false
        property var wifiDevice: null
        property var wifiNetworks: null
        property bool scanning: false
        property string statusText: "looking for wifi..."
        property int netCount: wifiNetworks ? wifiNetworks.values.length : 0

        function scan() {
            if (!wifiDevice) return;
            wifiDevice.scannerEnabled = false;
            wifiDevice.scannerEnabled = true;
            scanning = true;
            scanTimer.restart();
        }

        function findWifiDevice() {
            if (!Networking || !Networking.devices) {
                wifiSection.statusText = "Networking API unavailable";
                return;
            }
            var devices = Networking.devices.values;
            wifiSection.statusText = "device count: " + devices.length;
            for (var i = 0; i < devices.length; i++) {
                var d = devices[i];
                if (!d) continue;
                if (d.scannerEnabled !== undefined) {
                    wifiDevice = d;
                    wifiNetworks = d.networks;
                    wifiDevice.scannerEnabled = true;
                    wifiSection.statusText = "found: " + d.name;
                    return;
                }
            }
        }

        Timer {
            id: scanTimer
            interval: 3000
            running: false
            onTriggered: {
                wifiSection.scanning = false;
            }
        }

        Timer {
            interval: 1000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: {
                if (!wifiSection.wifiDevice) {
                    wifiSection.findWifiDevice();
                } else {
                    stop();
                }
            }
        }

        Timer {
            interval: 60000
            running: true
            repeat: true
            onTriggered: {
                if (!wifiSection.wifiDevice || !wifiSection.wifiDevice.name)
                    wifiSection.findWifiDevice();
            }
        }
    }

    // =========================================================
    // system info - who am i, where am i
    // =========================================================

    Item {
        id: sysInfo
        visible: false
        property string hostname: "--"
        property string os: "--"
        property string kernel: "--"
        property string uptimeStr: "--"

        property int uptimeSeconds: 0
        property string displayUptime: {
            var days = Math.floor(uptimeSeconds / 86400);
            var hours = Math.floor((uptimeSeconds % 86400) / 3600);
            var mins = Math.floor((uptimeSeconds % 3600) / 60);
            var parts = [];
            if (days > 0) parts.push(days + "d");
            if (hours > 0) parts.push(hours + "h");
            parts.push(mins + "m");
            return parts.join(" ");
        }

        Process {
            id: sysFetchProc
            running: true
            command: ["sh", "-c", "(. /etc/os-release 2>/dev/null && echo \"$PRETTY_NAME\" || uname -o) > /tmp/lazerbar-os 2>/dev/null; uname -r > /tmp/lazerbar-kernel 2>/dev/null"]
            onExited: (code) => {
                if (code === 0) {
                    osFile.reload();
                    kernelFile.reload();
                }
            }
        }

        FileView { id: hostnameFile; path: "/proc/sys/kernel/hostname"; onLoaded: sysInfo.hostname = text().trim(); Component.onCompleted: reload() }
        FileView { id: osFile; path: "/tmp/lazerbar-os"; onLoaded: sysInfo.os = text().trim() }
        FileView { id: kernelFile; path: "/tmp/lazerbar-kernel"; onLoaded: sysInfo.kernel = text().trim() }

        Timer {
            interval: 5000
            running: true
            repeat: true
            onTriggered: uptimeFile.reload()
        }

        FileView {
            id: uptimeFile
            path: "/proc/uptime"
            onLoaded: {
                try {
                    var raw = text().trim();
                    if (!raw) return;
                    sysInfo.uptimeSeconds = Math.floor(parseFloat(raw.split(" ")[0]));
                } catch (e) {}
            }
        }

        Component.onCompleted: uptimeFile.reload()
    }
}
