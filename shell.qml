//@ pragma UseQApplication
import Quickshell
import QtQuick
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Io
import Qt5Compat.GraphicalEffects
import Quickshell.Services.Notifications
import "./"

ShellRoot {

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    ListModel {
        id: notifHistory
    }

    NotificationServer {
        id: notifServer
        actionsSupported: true
        onNotification: (n) => {
            n.tracked = true;
            notifHistory.append({
                notifObj: n,
                summary: n.summary,
                body: n.body,
                appName: n.appName,
                desktopEntry: n.desktopEntry,
                notifImage: n.image
            });
        }
    }

PanelWindow {
    id: window
    anchors {
        left: true
        top: true
        right: true
    }

    color: "transparent"
    implicitHeight: 50

        Rectangle {
            anchors.fill: parent
            color: settingsPanel.bgColor
            opacity: settingsPanel.barOpacity
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        Item {
            id: barContent
            width: parent.width
            height: 100

            y: -100 

            NumberAnimation on y {
                from: -100
                to: -70
                duration: 600
                easing.type: Easing.OutBack
                easing.overshoot: 2 
                running: true
            }

            Item {
                id: visibleArea
                width: parent.width
                height: 50
                y: 70 

                // volume bar thingy
                MouseArea {
                    id: volumeControl
                    width: 20
                    height: 40
                    x: parent.width - width - 300
                    anchors.verticalCenter: parent.verticalCenter
                    hoverEnabled: true
                    visible: settingsPanel.showAudioVis
                    
                    onWheel: (wheel) => {
                        if (Pipewire && Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
                            let audio = Pipewire.defaultAudioSink.audio;
                            let delta = wheel.angleDelta.y > 0 ? settingsPanel.volumeStep : -settingsPanel.volumeStep;
                            let newVol = Math.max(0, Math.min(1, audio.volume + delta));
                            audio.volume = newVol;
                        }
                    }

                    Rectangle {
                        anchors.centerIn: parent 
                        height: parent.height * 0.7 
                        width: volumeControl.containsMouse ? 4 : 2 // girth
                            
                        color: settingsPanel.borderColor
                        radius: 3
                        clip: true

                        Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                        Rectangle {
                            width: parent.width
                            anchors.bottom: parent.bottom
                            radius: 3
                            color: '#ffffff'
                                
                            height: (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) 
                                    ? parent.height * Pipewire.defaultAudioSink.audio.volume 
                                    : 0
                                
                            Behavior on height { NumberAnimation { duration: 150 } }
                        }
                    }
                }

                // media buttons - beatmaps and jukebox side by side
                Row {
                    spacing: 4
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: visibleArea.right
                    anchors.rightMargin: 315

                    Rectangle {
                        width: 38
                        height: 38
                        radius: 7

                        color: mouseAreaBeatmap.containsMouse ? "#34ffffff" : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Image {
                            smooth: true
                            mipmap: true
                            anchors.fill: parent
                            anchors.margins: 6
                            source: `file://${Quickshell.env("HOME")}/.config/quickshell/lazerbar/assets/beatmap.png`
                            fillMode: Image.PreserveAspectFit
                            opacity: mouseAreaBeatmap.containsMouse ? 1.0 : 0.8
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }

                        MouseArea {
                            id: mouseAreaBeatmap
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Quickshell.execDetached({
                                    command: ["xdg-open", "https://osu.ppy.sh/beatmapsets"]
                                })
                            }
                        }
                    }


                Rectangle {
                        id: mediaBtn
                        width: 38
                        height: 38
                        radius: 7
                        visible: settingsPanel.showMediaDisplay

                        readonly property var activePlayer: (Mpris && Mpris.players && Mpris.players.values.length > 0) 
                            ? (Mpris.players.values.find(p => p.playbackState === MprisPlaybackState.Playing) || Mpris.players.values[0]) 
                            : null

                        color: mouseAreaMedia.containsMouse ? "#34ffffff" : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Image {
                            smooth: true
                            mipmap: true
                            anchors.fill: parent
                            anchors.margins: 6
                            source: `file://${Quickshell.env("HOME")}/.config/quickshell/lazerbar/assets/music.png`
                            fillMode: Image.PreserveAspectFit
                            opacity: mouseAreaMedia.containsMouse ? 1.0 : 0.8
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }

                        MouseArea {
                            id: mouseAreaMedia
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mediaPopup.visible = !mediaPopup.visible
                        }
                    }
                }

                // workspaces
                    Item {
                        id: wsRootItem
                        width: wsRow.width
                        height: 50
                        anchors.centerIn: parent
                        
                        Item {
                            width: wsRow.width
                            height: 42 
                            anchors.centerIn: parent

                        Row {
                            id: wsRow
                            spacing: 15
                            anchors.top: parent.top
                            
                            Repeater {
                                id: wsRepeater
                                model: [
                                    { id: 1, name: "home" },
                                    { id: 2, name: "RulesetOsu" },
                                    { id: 3, name: "RulesetTaiko" },
                                    { id: 4, name: "RulesetCatch" },
                                    { id: 5, name: "RulesetMania" }
                                ]

                                delegate: Item {
                                    width: 38
                                    height: 38

                                    property bool isActive: Hyprland.focusedWorkspace?.id === modelData.id
                                    property bool isHovered: mouseAreaWs.containsMouse

                                    Rectangle {
                                        id: bg
                                        anchors.fill: parent
                                        radius: 8
                                        color: isHovered ? "#34ffffff" : "transparent"

                                        Behavior on color {
                                            ColorAnimation { duration: 150 }
                                        }

                                    Image {
                                        id: wsIcon
                                        anchors.fill: parent
                                        anchors.margins: 6
                                        source: `file://${Quickshell.env("HOME")}/.config/quickshell/lazerbar/assets/${modelData.name}.png`
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                        mipmap: true
                                        antialiasing: true
                                        visible: false

                                        layer.enabled: true
                                        layer.smooth: true
                                        layer.textureSize: Qt.size(width * 2, height * 2)
                                    }

                                    ColorOverlay {
                                        anchors.fill: wsIcon
                                        source: wsIcon
                                        antialiasing: true

                                        color: isActive ? settingsPanel.activeWsColor : "#ffffff"

                                        Behavior on color {
                                            ColorAnimation { duration: 120 }
                                        }
                                    }

                                    MouseArea {
                                        id: mouseAreaWs
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Hyprland.dispatch("workspace " + modelData.id)
                                    }
                                }
                            }
                        }
                    }
                    
                        // the "you are here" line
                        Rectangle {
                            id: activeBar
                            width: 20
                            height: 2.4
                            radius: 1
                            color: settingsPanel.activeWsColor
                            z: 10
                            anchors.top: wsRow.bottom
                            anchors.topMargin: 2
                            opacity: (Hyprland.focusedWorkspace?.id >= 1 && Hyprland.focusedWorkspace?.id <= 5) ? 1 : 0
                            x: {
                                var currentId = Hyprland.focusedWorkspace?.id;
                                if (currentId === undefined) return 0;
                                
                                var index = currentId - 1;
                                if (index >= 0 && index < wsRepeater.count) {
                                    var item = wsRepeater.itemAt(index);
                                    if (item) return item.x + (item.width / 2) - (width / 2);
                                }
                                return 0;
                            }

                            Behavior on x {
                                NumberAnimation {
                                    duration: 400
                                    easing.type: Easing.OutBack 
                                }
                            }
                        }
                    }
                }

                // clock - tracking the seconds i'll never get back
                SystemClock {
                    id: clock
                    precision: SystemClock.Seconds
                }

                Text {
                    width: 130
                    color: '#ffffff'
                    text: Qt.formatDateTime(clock.date, "h:mm:ss AP")
                    font.family: "Torus"
                    font.pointSize: 15
                    anchors.top: parent.top
                    anchors.topMargin: 8
                    anchors.right: parent.right
                    anchors.rightMargin: 80
                }

                // runtime - "look at me, i've been on my pc for 8 hours"
                property int elapsedSeconds: 0

                function formatTime(totalSeconds) {
                    let hours = Math.floor(totalSeconds / 3600);
                    let minutes = Math.floor((totalSeconds % 3600) / 60);
                    let seconds = totalSeconds % 60;
                    return [hours, minutes, seconds].map(v => v < 10 ? "0" + v : v).join(":");
                }

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: visibleArea.elapsedSeconds++
                }

                Row {
                    x: parent.width - width - 122
                    anchors.top: parent.top
                    anchors.topMargin: 30
                    spacing: 4
                    visible: settingsPanel.showSessionTimer

                    Text {
                        text: "running"
                        font.pixelSize: 11
                        font.family: "Torus"
                        color: settingsPanel.accentColor
                        font.bold: true
                    }

                    Text {
                        width: 50 
                        text: visibleArea.formatTime(visibleArea.elapsedSeconds)
                        font.pixelSize: 11
                        font.family: "Torus"
                        color: settingsPanel.accentColor
                        horizontalAlignment: Text.AlignLeft
                        font.bold: true
                    }
                }

                // analog clock - canvas is pain but it looks cool
                Item {
                    width: 30
                    height: 30
                    x: parent.width - width - 220
                    anchors.verticalCenter: parent.verticalCenter
                    visible: settingsPanel.showAnalogClock

                    Timer {
                        interval: 1000
                        running: true
                        repeat: true
                        onTriggered: canvas.requestPaint()
                    }

                    Canvas {
                        id: canvas
                        anchors.fill: parent
                        antialiasing: true

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            var centerX = width / 2;
                            var centerY = height / 2;
                            var radius = (width / 2) - 1;
                            var date = new Date();
                            var hours = date.getHours();
                            var minutes = date.getMinutes();
                            var seconds = date.getSeconds();

                            ctx.beginPath();
                            ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
                            ctx.strokeStyle = '#ffffff';
                            ctx.lineWidth = 1.75;
                            ctx.stroke();

                            function drawHand(angle, length, width, color) {
                                ctx.save();
                                ctx.beginPath();
                                ctx.strokeStyle = color;
                                ctx.lineWidth = width;
                                ctx.lineCap = "round";
                                ctx.translate(centerX, centerY);
                                ctx.rotate(angle);
                                ctx.moveTo(0, 0);
                                ctx.lineTo(0, -length);
                                ctx.stroke();
                                ctx.restore();
                            }

                            var hourAngle = (hours % 12 + minutes / 60) * Math.PI / 6;
                            var minAngle = (minutes + seconds / 60) * Math.PI / 30;
                            var secAngle = seconds * Math.PI / 30;

                            drawHand(hourAngle, radius * 0.5, 1.65, '#ffffff');
                            drawHand(minAngle, radius * 0.8, 1.65, '#ffffff');
                            drawHand(secAngle, radius * 1, 1.60, settingsPanel.accentColor);
                            drawHand(secAngle, radius * -0.3, 1.5, settingsPanel.accentColor);
                        }
                    }
                }

                // settings - where the magic (and bugs) happen
                Rectangle {
                    id: settingsButton
                    width: 50
                    height: 38
                    radius: 7
                    anchors.verticalCenter: parent.verticalCenter
                    x: 10

                    color: mouseAreaSettings.containsMouse ? "#34ffffff" : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Image {
                        anchors.fill: parent
                        anchors.margins: 6
                        source: `file://${Quickshell.env("HOME")}/.config/quickshell/lazerbar/assets/settings.png`
                        fillMode: Image.PreserveAspectFit
                        opacity: mouseAreaSettings.containsMouse ? 1.0 : 0.8
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    MouseArea {
                        id: mouseAreaSettings
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: settingsWindow.visible = !settingsWindow.visible
                    }
                }

                // tray - where apps go to hide, or not really
                Row {
                    height: 38
                    anchors.verticalCenter: parent.verticalCenter
                    x: settingsButton.x + settingsButton.width + 10
                    spacing: 8

                    Repeater {
                        model: SystemTray.items
                        delegate: Rectangle {
                            width: 38
                            height: 38
                            radius: 7
                            color: trayMouse.containsMouse ? "#34ffffff" : "transparent"
                            
                            IconImage {
                                anchors.fill: parent
                                anchors.margins: 8
                                source: modelData.icon
                                smooth: true
                            }

                            MouseArea {
                                id: trayMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: (mouse) => {
                                    if (mouse.button === Qt.RightButton) modelData.display(window, mouse.x, mouse.y)
                                    else modelData.activate()
                                }
                            }
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                    }
                }

                // control center - cool thing i think
                Rectangle {
                    width: 50
                    height: 38
                    radius: 7
                    anchors.verticalCenter: parent.verticalCenter
                    x: parent.width - width - 10

                    color: mouseAreaCC.containsMouse ? "#34ffffff" : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }

                    MouseArea {
                        id: mouseAreaCC
                        anchors.fill: parent
                        hoverEnabled: true
                        
                        onClicked: ccWindow.visible = !ccWindow.visible
                    }

                    Image {
                        anchors.fill: parent
                        anchors.margins: 6
                        source: `file://${Quickshell.env("HOME")}/.config/quickshell/lazerbar/assets/controlcenter.png`
                        fillMode: Image.PreserveAspectFit
                        opacity: mouseAreaCC.containsMouse ? 1.0 : 0.8
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                }

            } // visibleArea
        } // barContent

    } // PanelWindow

// notifications - because i can't go 10 milliseconds without dopamine
    PopupWindow {
        id: notifPopup
        implicitWidth: 400
        // don't set this to 0 or wayland will literally kill you
        implicitHeight: Math.max(notifList.contentHeight, 1)
        visible: settingsPanel.showNotifPopup

        anchor.window: window
        anchor.rect.x: window.width - 410
        anchor.rect.y: 60

        mask: Region {
            item: notifList
        }

        color: "transparent"

        ListView {
            id: notifList
            anchors.fill: parent
            spacing: 12
            model: notifServer.trackedNotifications
            implicitHeight: contentHeight

            delegate: NotificationCard {
                notificationObject: modelData
                width: 400
                autoDismiss: settingsPanel.autoDismiss
                popupDuration: settingsPanel.popupDuration
                bgColor: settingsPanel.bgColor
                surfaceColor: settingsPanel.surfaceColor
                borderColor: settingsPanel.borderColor
                borderHoverColor: "#5d5d63"
            }
        }
    }

PanelWindow {
        id: ccWindow
        anchors {
            right: true
            top: true
        }
        
        margins {
            top: 5
            // When closed, we set a margin larger than the window width
            right: 5
        }

        visible: false
        color: "transparent"
        focusable: true
        implicitWidth: 380
        implicitHeight: 750

        ControlCenter {
            anchors.fill: parent
            panelVisible: ccWindow.visible
            notifModel: notifHistory
            autoDismiss: settingsPanel.autoDismiss
            accentColor: settingsPanel.accentColor
            bgColor: settingsPanel.bgColor
            surfaceColor: settingsPanel.surfaceColor
            borderColor: settingsPanel.borderColor
            showDemoBattery: settingsPanel.showDemoBattery
            showWeather: settingsPanel.showWeather
            wifiEnabled: settingsPanel.wifiEnabled
            useFahrenheit: settingsPanel.useFahrenheit
            pomodoroWorkDuration: settingsPanel.pomodoroWorkDuration
            pomodoroBreakDuration: settingsPanel.pomodoroBreakDuration
            onLockRequested: {
                ccWindow.visible = false
                sessionLock.locked = true
            }
            onExitConfirmRequested: (label, cmd) => {
                exitConfirmPopup.pendingCommand = cmd
                exitConfirmPopup.visible = true
            }
        }
    }

PanelWindow {
        id: settingsWindow
        anchors {
            left: true
            top: true
        }
        
        margins {
            top: 5
            // When closed, we set a margin larger than the window width
            left: 5
        }

        visible: false
        color: "transparent"
        focusable: true
        implicitWidth: 380
        implicitHeight: 750

        // settings panel - the control room for your questionable choices
        Settings {
            id: settingsPanel
            anchors.fill: parent
            onSetWallpaperRequested: (filePath) => wallpaperChanger.setDirect(filePath)
            onOpenWallpaperPicker: wallpaperSelector.show()
        }
    }

    PanelWindow {
        id: mediaPopup
        visible: false
        color: "transparent"

        anchors {
            right: true
            top: true
        }

        margins {
            top: 10
            right: 150
        }

        implicitWidth: 350
        implicitHeight: 380

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: settingsPanel.bgColor
            border.color: settingsPanel.borderColor
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                // header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "now playing"
                        color: "#888888"
                        font.family: "Torus"
                        font.pixelSize: 11
                    }

                    Item { Layout.fillWidth: true }
                }

                // album art
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 200
                    radius: 10
                    color: "#2a2a32"
                    clip: true

                    property string lastArt: ""

                    readonly property var activePlayer: mediaBtn.activePlayer

                    Image {
                        id: popupArt
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        source: {
                            var p = parent.activePlayer;
                            p && p.trackArtUrl ? p.trackArtUrl : parent.lastArt
                        }
                        onStatusChanged: {
                            if (status === Image.Ready && source && source !== parent.lastArt)
                                parent.lastArt = source;
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: parent.activePlayer?.trackTitle?.[0]?.toUpperCase() ?? "♪"
                        color: "#555"
                        font.pixelSize: 48
                        visible: !parent.activePlayer?.trackArtUrl && !parent.lastArt
                    }
                }

                // track info
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    MarqueeText {
                        Layout.fillWidth: true
                        height: 22
                        label: {
                            var p = mediaBtn.activePlayer;
                            p?.trackTitle ?? "no media playing"
                        }
                        color: "#ffffff"
                        fontSize: 15
                        bold: true
                    }

                    Text {
                        Layout.fillWidth: true
                        text: {
                            var p = mediaBtn.activePlayer;
                            p?.trackArtist ?? ""
                        }
                        color: "#888888"
                        font.family: "Torus"
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }
                }

                // playback controls
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Item { Layout.fillWidth: true }

                    MediaButton {
                        text: "󰒮"
                        onClicked: { var p = mediaBtn.activePlayer; if (p) p.previous() }
                        surfaceColor: settingsPanel.surfaceColor
                    }

                    MediaButton {
                        text: {
                            var p = mediaBtn.activePlayer;
                            p?.playbackState === MprisPlaybackState.Playing ? "󰏤" : "󰐊"
                        }
                        onClicked: {
                            var p = mediaBtn.activePlayer;
                            if (!p) return;
                            if (p.playbackState === MprisPlaybackState.Playing) p.pause();
                            else p.play();
                        }
                        btnWidth: 44
                        btnHeight: 44
                        surfaceColor: settingsPanel.surfaceColor
                    }

                    MediaButton {
                        text: "󰒭"
                        onClicked: { var p = mediaBtn.activePlayer; if (p) p.next() }
                        surfaceColor: settingsPanel.surfaceColor
                    }

                    Item { Layout.fillWidth: true }
                }
            }
        }
    }

// exit confirmation - the "oh god what have i done" dialog
// osu!lazer style because bad decisions deserve good aesthetics
PanelWindow {
    id: exitConfirmPopup

    visible: false
    color: "transparent"
    focusable: true

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    // the command we're about to unleash upon the unsuspecting system
    property string pendingCommand: ""

    // existential dread overlay
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha("#000000", 0.88)

        // the "are you sure?" box - last stop before the void
        Rectangle {
            id: dialogBox

            width: 820
            height: 520

            anchors.centerIn: parent

            radius: 22
            color: settingsPanel.bgColor

            // darker bottom strip - for dramatic effect
            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }

                height: 165
                color: Qt.darker(settingsPanel.bgColor, 2.5)
                radius: 22
            }

            // content that questions your life choices
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 40
                spacing: 0

                // breathing room at the top - contemplate your mortality
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 135
                }

                // the big question
                Text {
                    Layout.alignment: Qt.AlignHCenter

                    text: "Are you sure you want to exit Hyprland?"
                    color: "white"
                    font.family: "Torus"
                    font.pixelSize: 34
                    font.weight: Font.Medium
                }

                // the "you can still walk away" tagline
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 16

                    text: "Last chance to turn back"
                    color: "white"
                    opacity: 0.8
                    font.family: "Torus"
                    font.pixelSize: 18
                }

                // push buttons to the bottom - gravity of the situation
                Item {
                    Layout.fillHeight: true
                }

                // the "i regret nothing" button
                Item {
                    Layout.alignment: Qt.AlignHCenter

                    width: 680
                    height: 72

                    Canvas {
                        id: confirmCanvas
                        anchors.fill: parent
                        antialiasing: true

                        property bool hovered: false

                        onPaint: {
                            const ctx = getContext("2d");
                            ctx.reset();

                            const w = width;
                            const h = height;
                            const s = 18;

                            // parallelogram: because rectangles are cowards
                            ctx.beginPath();
                            ctx.moveTo(s, 0);
                            ctx.lineTo(w, 0);
                            ctx.lineTo(w - s, h);
                            ctx.lineTo(0, h);
                            ctx.closePath();

                            const fillC = hovered
                                ? Qt.lighter(settingsPanel.accentColor, 1.15)
                                : settingsPanel.accentColor;

                            ctx.fillStyle = fillC;
                            ctx.fill();

                            // that subtle edge glow - chefs kiss
                            ctx.strokeStyle = Qt.lighter(fillC, 1.08);
                            ctx.lineWidth = 1;
                            ctx.stroke();
                        }

                        Connections {
                            target: confirmMouse

                            function onContainsMouseChanged() {
                                confirmCanvas.hovered = confirmMouse.containsMouse;
                                confirmCanvas.requestPaint();
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent

                        text: "Let me out!"
                        color: "white"

                        font.family: "Torus"
                        font.pixelSize: 20
                        font.bold: true
                    }

                    MouseArea {
                        id: confirmMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            if (exitConfirmPopup.pendingCommand) {
                                Quickshell.execDetached({
                                    command: [
                                        "sh",
                                        "-c",
                                        exitConfirmPopup.pendingCommand
                                    ]
                                });
                            }

                            // close yourself, you're done here
                            exitConfirmPopup.visible = false;
                        }
                    }
                }

                // gap of hesitation
                Item {
                    Layout.preferredHeight: 10
                }

                // the "i've seen the error of my ways" button
                Item {
                    Layout.alignment: Qt.AlignHCenter

                    width: 680
                    height: 72

                    Canvas {
                        id: cancelCanvas
                        anchors.fill: parent
                        antialiasing: true

                        property bool hovered: false

                        onPaint: {
                            const ctx = getContext("2d");
                            ctx.reset();

                            const w = width;
                            const h = height;
                            const s = 18;

                            // same slanted shape, same energy
                            ctx.beginPath();
                            ctx.moveTo(s, 0);
                            ctx.lineTo(w, 0);
                            ctx.lineTo(w - s, h);
                            ctx.lineTo(0, h);
                            ctx.closePath();

                            const fillC = hovered
                                ? Qt.lighter(settingsPanel.surfaceColor, 1.4)
                                : settingsPanel.surfaceColor;

                            ctx.fillStyle = fillC;
                            ctx.fill();

                            ctx.strokeStyle = Qt.lighter(fillC, 1.15);
                            ctx.lineWidth = 1;
                            ctx.stroke();
                        }

                        Connections {
                            target: cancelMouse

                            function onContainsMouseChanged() {
                                cancelCanvas.hovered = cancelMouse.containsMouse;
                                cancelCanvas.requestPaint();
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent

                        text: "Nevermind!"
                        color: "white"

                        font.family: "Torus"
                        font.pixelSize: 20
                        font.bold: true
                    }

                    MouseArea {
                        id: cancelMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            // phew, that was close
                            exitConfirmPopup.visible = false;
                        }
                    }
                }

                // bottom padding - gotta land somewhere
                Item {
                    Layout.preferredHeight: 28
                }
            }
        }
    }
} // i promise this is the last "are you sure?" dialog. probably.

    // app launcher - separate module so you can bind it to a key and feel powerful
    AppLauncher {
        id: appLauncher
        surfaceColor: settingsPanel.surfaceColor
        accentColor: settingsPanel.accentColor
        borderColor: settingsPanel.borderColor
    }

    // wallpaper panel - covering your desktop's existential void
    WallpaperChanger {
        id: wallpaperChanger
        enabled: settingsPanel.wallpaperEnabled
    }

    // wallpaper selector - grid browser
    WallpaperSelector {
        id: wallpaperSelector
        accentColor: settingsPanel.accentColor
        bgColor: settingsPanel.bgColor
        surfaceColor: settingsPanel.surfaceColor
        borderColor: settingsPanel.borderColor
        currentWallpaper: wallpaperChanger.savedWallpaper
        onWallpaperApplyRequested: (filePath) => wallpaperChanger.setDirect(filePath)
    }

    // lock screen
    WlSessionLock {
        id: sessionLock

        readonly property bool showDemoBattery: settingsPanel.showDemoBattery

        WlSessionLockSurface {
            color: "#000000"

            Lockscreen {
                anchors.fill: parent
                accentColor: settingsPanel.accentColor
                surfaceColor: settingsPanel.surfaceColor
                bgColor: settingsPanel.bgColor
                borderColor: settingsPanel.borderColor
                showDemoBattery: sessionLock.showDemoBattery
                onUnlocked: sessionLock.locked = false
            }
        }
    }

} // ShellRoot
