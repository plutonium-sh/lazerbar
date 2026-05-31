import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import Quickshell.Io

// behold, the constitution of this entire project
Rectangle {
    id: settingsContainer

    width: 380
    height: 750

    color: settingsContainer.bgColor
    border.color: settingsContainer.borderColor
    border.width: 3
    radius: 12

    property bool showAudioVis: true
    property bool showAnalogClock: true
    property bool showSessionTimer: true
    property bool showNotifPopup: true
    property bool autoDismiss: true
    property bool showDemoBattery: false
    property bool showWeather: true
    property bool wifiEnabled: true
    property bool useFahrenheit: false
    property int pomodoroWorkDuration: 25
    property int pomodoroBreakDuration: 5
    property bool showMediaDisplay: true
    property bool wallpaperEnabled: true
    property string wallpaperSource: "osu"
    property string prefetchedWallpaper: ""
    property var barValues: []
    property int barCount: 24
    property string accentColor: "#ec8fbe"
    property string bgColor: "#181818"
    property string surfaceColor: "#1e1e24"
    property string borderColor: "#333333"
    property string activeWsColor: "#01eb9d"
    property int popupDuration: 5
    property real volumeStep: 0.05
    property string visColor: "#ec8fbe"
    property int maxPopupNotifs: 5
    property real barOpacity: 1.0
    property bool hexInput: false
    property bool spectrumHexInput: false
    property var customThemes: []

    signal setWallpaperRequested(string filePath)
    signal openWallpaperPicker()

    property var activePlayer: (Mpris && Mpris.players && Mpris.players.values.length > 0)
        ? (Mpris.players.values.find(p => p.playbackState === MprisPlaybackState.Playing) || Mpris.players.values[0])
        : null

    property var categories: [
        { name: "interface", icon: "user-interface.png" },
        { name: "audio", icon: "audio.png" },
        { name: "notifications", icon: "notification.png" },
        { name: "media", icon: "music.png" },
        { name: "appearance", icon: "skin-b.png" },
    ]

    property int activeCategory: 0

    property bool loadingSettings: true

    // settings archeology - excavating your preferences
    FileView {
        path: Quickshell.env("HOME") + "/.config/quickshell/lazerbar/settings.json"
        onLoaded: {
            try {
                var data = JSON.parse(text().trim());
                if (!data) return;
                settingsContainer.loadingSettings = true;
                if (data.accentColor) settingsContainer.accentColor = data.accentColor;
                if (data.bgColor) settingsContainer.bgColor = data.bgColor;
                if (data.surfaceColor) settingsContainer.surfaceColor = data.surfaceColor;
                if (data.borderColor) settingsContainer.borderColor = data.borderColor;
                if (data.activeWsColor) settingsContainer.activeWsColor = data.activeWsColor;
                if (data.showAudioVis !== undefined) settingsContainer.showAudioVis = data.showAudioVis;
                if (data.showAnalogClock !== undefined) settingsContainer.showAnalogClock = data.showAnalogClock;
                if (data.showSessionTimer !== undefined) settingsContainer.showSessionTimer = data.showSessionTimer;
                if (data.showNotifPopup !== undefined) settingsContainer.showNotifPopup = data.showNotifPopup;
                if (data.autoDismiss !== undefined) settingsContainer.autoDismiss = data.autoDismiss;
                if (data.showDemoBattery !== undefined) settingsContainer.showDemoBattery = data.showDemoBattery;
                if (data.showWeather !== undefined) settingsContainer.showWeather = data.showWeather;
                if (data.wifiEnabled !== undefined) settingsContainer.wifiEnabled = data.wifiEnabled;
                if (data.useFahrenheit !== undefined) settingsContainer.useFahrenheit = data.useFahrenheit;
                if (data.pomodoroWorkDuration) settingsContainer.pomodoroWorkDuration = data.pomodoroWorkDuration;
                if (data.pomodoroBreakDuration) settingsContainer.pomodoroBreakDuration = data.pomodoroBreakDuration;
                if (data.showMediaDisplay !== undefined) settingsContainer.showMediaDisplay = data.showMediaDisplay;
                if (data.popupDuration) settingsContainer.popupDuration = data.popupDuration;
                if (data.volumeStep) settingsContainer.volumeStep = data.volumeStep;
                if (data.visColor) settingsContainer.visColor = data.visColor;
                if (data.maxPopupNotifs) settingsContainer.maxPopupNotifs = data.maxPopupNotifs;
                if (data.barOpacity !== undefined) settingsContainer.barOpacity = data.barOpacity;
                if (data.hexInput !== undefined) settingsContainer.hexInput = data.hexInput;
                if (data.spectrumHexInput !== undefined) settingsContainer.spectrumHexInput = data.spectrumHexInput;
                if (data.wallpaperEnabled !== undefined) settingsContainer.wallpaperEnabled = data.wallpaperEnabled;
                if (data.wallpaperSource !== undefined) settingsContainer.wallpaperSource = data.wallpaperSource;
                settingsContainer.loadingSettings = false;
            } catch (e) {}
        }
    }

    FileView {
        path: Quickshell.env("HOME") + "/.config/quickshell/lazerbar/custom-themes.json"
        onLoaded: {
            try {
                var data = JSON.parse(text().trim());
                if (data && Array.isArray(data))
                    settingsContainer.customThemes = data;
            } catch (e) {}
        }
    }

    // the laziest Process in the world (placeholder king)
    Process {
        id: settingsSaver
        command: ["true"]
    }

    Process {
        id: customThemeSaver
        running: false
    }

    // the modem's on/off switch, now with 100% more nmcli
    Process {
        id: wifiProc
        running: false
    }

    // serializing the entire universe every 500ms
    Timer {
        id: saveDebounce
        interval: 500
        running: false
        repeat: false
        onTriggered: {
            if (settingsContainer.loadingSettings) return;
            var data = JSON.stringify({
                accentColor: settingsContainer.accentColor,
                bgColor: settingsContainer.bgColor,
                surfaceColor: settingsContainer.surfaceColor,
                borderColor: settingsContainer.borderColor,
                activeWsColor: settingsContainer.activeWsColor,
                showAudioVis: settingsContainer.showAudioVis,
                showAnalogClock: settingsContainer.showAnalogClock,
                showSessionTimer: settingsContainer.showSessionTimer,
                showNotifPopup: settingsContainer.showNotifPopup,
                autoDismiss: settingsContainer.autoDismiss,
                showDemoBattery: settingsContainer.showDemoBattery,
                showWeather: settingsContainer.showWeather,
                wifiEnabled: settingsContainer.wifiEnabled,
                useFahrenheit: settingsContainer.useFahrenheit,
                pomodoroWorkDuration: settingsContainer.pomodoroWorkDuration,
                pomodoroBreakDuration: settingsContainer.pomodoroBreakDuration,
                showMediaDisplay: settingsContainer.showMediaDisplay,
                popupDuration: settingsContainer.popupDuration,
                volumeStep: settingsContainer.volumeStep,
                visColor: settingsContainer.visColor,
                maxPopupNotifs: settingsContainer.maxPopupNotifs,
                barOpacity: settingsContainer.barOpacity,
                hexInput: settingsContainer.hexInput,
                spectrumHexInput: settingsContainer.spectrumHexInput,
                wallpaperEnabled: settingsContainer.wallpaperEnabled,
                wallpaperSource: settingsContainer.wallpaperSource
            });
            var path = Quickshell.env("HOME") + "/.config/quickshell/lazerbar/settings.json";
            settingsSaver.command = ["sh", "-c", "echo '" + data.replace(/'/g, "'\\''") + "' > '" + path + "'"];
            settingsSaver.running = true;
        }
    }

    // save early, save often, save again for good luck
    function autoSave() {
        if (!settingsContainer.loadingSettings)
            saveDebounce.restart();
    }

    function saveCustomThemes() {
        var data = JSON.stringify(settingsContainer.customThemes);
        var path = Quickshell.env("HOME") + "/.config/quickshell/lazerbar/custom-themes.json";
        customThemeSaver.command = ["sh", "-c", "echo '" + data.replace(/'/g, "'\\''") + "' > '" + path + "'"];
        customThemeSaver.running = true;
    }

    // the surveillance state of settings
    Connections {
        target: settingsContainer
        function onAccentColorChanged() { autoSave() }
        function onBgColorChanged() { autoSave() }
        function onSurfaceColorChanged() { autoSave() }
        function onBorderColorChanged() { autoSave() }
        function onActiveWsColorChanged() { autoSave() }
        function onShowAudioVisChanged() { autoSave() }
        function onShowAnalogClockChanged() { autoSave() }
        function onShowSessionTimerChanged() { autoSave() }
        function onShowNotifPopupChanged() { autoSave() }
        function onAutoDismissChanged() { autoSave() }
        function onShowDemoBatteryChanged() { autoSave() }
        function onShowWeatherChanged() { autoSave() }
        function onWifiEnabledChanged() { autoSave() }
        function onUseFahrenheitChanged() { autoSave() }
        function onPomodoroWorkDurationChanged() { autoSave() }
        function onPomodoroBreakDurationChanged() { autoSave() }
        function onShowMediaDisplayChanged() { autoSave() }
        function onPopupDurationChanged() { autoSave() }
        function onVolumeStepChanged() { autoSave() }
        function onVisColorChanged() { autoSave() }
        function onMaxPopupNotifsChanged() { autoSave() }
        function onBarOpacityChanged() { autoSave() }
        function onHexInputChanged() { autoSave() }
        function onSpectrumHexInputChanged() { autoSave() }
        function onWallpaperEnabledChanged() { autoSave() }
        function onWallpaperSourceChanged() { autoSave() }
    }

    // wallpaper source definitions
    function getSourceInfo(source) {
        if (source === "mixed") {
            var pick = ["osu", "konachan"][Math.floor(Math.random() * 2)]
            return settingsContainer.getSourceInfo(pick)
        }
        switch(source) {
            case "osu":
                return {
                    apiUrl: "https://osu.ppy.sh/api/v2/seasonal-backgrounds",
                    jqExpr: "[.backgrounds[].url] | .[(now * 1000 | floor) % length] // empty"
                }
            case "konachan":
                return {
                    apiUrl: "https://konachan.net/post.json?limit=1&tags=rating%3Asafe+order%3Arandom",
                    jqExpr: "(.[0] | .jpeg_url // .file_url // empty)"
                }
            default:
                return settingsContainer.getSourceInfo("mixed")
        }
    }

    // builds a shell command with fallback chain through all sources
    function buildFallbackCmd(primaryUrl, primaryJq) {
        var cacheDir = Quickshell.env("HOME") + "/.config/quickshell/lazerbar/wallpapers"
        var curlOpts = "-s --connect-timeout 8 --max-time 20 --retry 2 --retry-delay 1"
        // primary + all fallbacks, tried in order until one works
        var fallbacks = [
            [primaryUrl, primaryJq],
            ["https://konachan.net/post.json?limit=1&tags=rating%3Asafe+order%3Arandom", "(.[0] | .jpeg_url // .file_url // empty)"],
            ["https://osu.ppy.sh/api/v2/seasonal-backgrounds", ".backgrounds[0].url // empty"]
        ]

        var script = ""
        for (var fi = 0; fi < fallbacks.length; fi++) {
            if (fi > 0) script += " || "
            script += "url=$(curl " + curlOpts + " '" + fallbacks[fi][0] + "' | jq -r '" + fallbacks[fi][1] + "') && [ -n \"$url\" ] && [ \"$url\" != \"null\" ]"
        }
        script += " || exit 1"

        script += " && fname=$(basename \"${url%%\\?*}\" | python3 -c 'import sys,urllib.parse; print(urllib.parse.unquote(sys.stdin.read().strip()))') && " +
            "mkdir -p '" + cacheDir + "' && fpath=\"" + cacheDir + "/$fname\" && " +
            "if [ -f \"$fpath\" ]; then echo \"$fpath\"; " +
            "else curl -sL --connect-timeout 15 --max-time 60 --retry 2 --retry-delay 2 -o \"$fpath\" \"$url\" && echo \"$fpath\"; fi"

        return script
    }

    function fetchWallpaper() {
        settingsContainer.fetchOne(false)
    }

    function fetchOne(isPrefetch) {
        var info = settingsContainer.getSourceInfo(settingsContainer.wallpaperSource)
        var cmd = settingsContainer.buildFallbackCmd(info.apiUrl, info.jqExpr)
        if (isPrefetch) {
            prefetchProc.command = ["sh", "-c", cmd]
            prefetchProc.running = true
        } else {
            apiFetchProc.command = ["sh", "-c", cmd]
            apiFetchProc.running = true
        }
    }

    Process {
        id: apiFetchProc
        running: false
        stdout: SplitParser {
            onRead: data => {
                var path = data.trim()
                if (path.length > 0)
                    settingsContainer.setWallpaperRequested(path)
            }
        }
    }

    Process {
        id: prefetchProc
        running: false
        stdout: SplitParser {
            onRead: data => {
                var path = data.trim()
                if (path.length > 0)
                    settingsContainer.prefetchedWallpaper = path
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 0
        spacing: 0

        Rectangle {
            Layout.preferredWidth: 48
            Layout.fillHeight: true
            color: settingsContainer.bgColor
            radius: 12

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 14
                spacing: 0

                Repeater {
                    model: categories

                    delegate: Item {
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 40

                        property bool isActive: index === settingsContainer.activeCategory

                        Rectangle {
                            anchors.fill: parent
                            anchors.leftMargin: 4
                            anchors.rightMargin: 4
                            radius: 8
                            color: mouseCat.containsMouse ? "#18ffffff" : "transparent"

                            Behavior on color {
                                ColorAnimation { duration: 120 }
                            }

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
                                onClicked: settingsContainer.activeCategory = index
                            }
                        }

                        Rectangle {
                            width: 3
                            height: 16
                            radius: 1.5
                            color: settingsContainer.accentColor
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 0
                            opacity: isActive ? 1 : 0

                            Behavior on opacity {
                                NumberAnimation { duration: 150 }
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            color: settingsContainer.borderColor
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"

            ColumnLayout {
                id: col
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                anchors.topMargin: 8
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: categories[settingsContainer.activeCategory].name
                    color: settingsContainer.accentColor
                    font.family: "Torus"
                    font.pixelSize: 16
                    font.bold: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: settingsContainer.borderColor
                }

                // interface tab
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: settingsContainer.activeCategory === 0
                    clip: true

                    Flickable {
                        anchors.fill: parent
                        contentHeight: col0.height
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        ColumnLayout {
                            id: col0
                            width: parent.width
                            spacing: 8

                            Text {
                                text: "bar settings"
                            color: "#888888"
                            font.family: "Torus"
                            font.pixelSize: 11
                        }

                        SettingToggle {
                            label: "show audio visualization"
                            toggled: settingsContainer.showAudioVis
                            onUserToggled: (val) => settingsContainer.showAudioVis = val
                            accentColor: settingsContainer.accentColor
                        }
                        SettingToggle {
                            label: "show battery indicator"
                            toggled: settingsContainer.showDemoBattery
                            onUserToggled: (val) => settingsContainer.showDemoBattery = val
                            accentColor: settingsContainer.accentColor
                        }
                        SettingToggle {
                            label: "use fahrenheit"
                            toggled: settingsContainer.useFahrenheit
                            onUserToggled: (val) => settingsContainer.useFahrenheit = val
                            accentColor: settingsContainer.accentColor
                        }
                        SettingToggle {
                            label: "show weather"
                            toggled: settingsContainer.showWeather
                            onUserToggled: (val) => settingsContainer.showWeather = val
                            accentColor: settingsContainer.accentColor
                        }
                        SettingToggle {
                            label: "wi-fi"
                            toggled: settingsContainer.wifiEnabled
                            onUserToggled: (val) => {
                                settingsContainer.wifiEnabled = val;
                                wifiProc.command = val ? ["nmcli", "radio", "wifi", "on"] : ["nmcli", "radio", "wifi", "off"];
                                wifiProc.running = true;
                            }
                            accentColor: settingsContainer.accentColor
                        }
                        SettingToggle {
                            label: "show analog clock"
                            toggled: settingsContainer.showAnalogClock
                            onUserToggled: (val) => settingsContainer.showAnalogClock = val
                            accentColor: settingsContainer.accentColor
                        }
                        SettingToggle {
                            label: "show session timer"
                            toggled: settingsContainer.showSessionTimer
                            onUserToggled: (val) => settingsContainer.showSessionTimer = val
                            accentColor: settingsContainer.accentColor
                        }
                        SettingToggle {
                            label: "show media display"
                            toggled: settingsContainer.showMediaDisplay
                            onUserToggled: (val) => settingsContainer.showMediaDisplay = val
                            accentColor: settingsContainer.accentColor
                        }
                        SettingToggle {
                            label: "wallpapers"
                            toggled: settingsContainer.wallpaperEnabled
                            onUserToggled: (val) => settingsContainer.wallpaperEnabled = val
                            accentColor: settingsContainer.accentColor
                        }

                        // go poke the internet for fresh pixels
                        Flow {
                            Layout.leftMargin: 16
                            Layout.fillWidth: true
                            spacing: 4
                            visible: settingsContainer.wallpaperEnabled

                            Text { text: "source"; color: "#888888"; font.family: "Torus"; font.pixelSize: 11; height: 26; verticalAlignment: Text.AlignVCenter }

                            Rectangle {
                                width: 38; height: 26; radius: 4
                                color: settingsContainer.wallpaperSource === "osu" ? settingsContainer.accentColor : settingsContainer.surfaceColor
                                Text { anchors.centerIn: parent; text: "osu"; color: settingsContainer.wallpaperSource === "osu" ? "#181818" : "#ffffff"; font.pixelSize: 11; font.bold: true }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: settingsContainer.wallpaperSource = "osu" }
                            }
                            Rectangle {
                                width: 44; height: 26; radius: 4
                                color: settingsContainer.wallpaperSource === "konachan" ? settingsContainer.accentColor : settingsContainer.surfaceColor
                                Text { anchors.centerIn: parent; text: "kona"; color: settingsContainer.wallpaperSource === "konachan" ? "#181818" : "#ffffff"; font.pixelSize: 11; font.bold: true }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: settingsContainer.wallpaperSource = "konachan" }
                            }
                            Rectangle {
                                width: 38; height: 26; radius: 4
                                color: settingsContainer.wallpaperSource === "mixed" ? settingsContainer.accentColor : settingsContainer.surfaceColor
                                Text { anchors.centerIn: parent; text: "mix"; color: settingsContainer.wallpaperSource === "mixed" ? "#181818" : "#ffffff"; font.pixelSize: 11; font.bold: true }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: settingsContainer.wallpaperSource = "mixed" }
                            }
                            Rectangle {
                                width: 26; height: 26; radius: 4; color: settingsContainer.accentColor
                                Text { anchors.centerIn: parent; text: "\u21BB"; color: "#181818"; font.pixelSize: 14; font.bold: true }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: settingsContainer.fetchWallpaper() }
                            }
                        }

                        Rectangle {
                            id: browseBtn
                            Layout.fillWidth: true
                            Layout.leftMargin: 16
                            Layout.rightMargin: 16
                            Layout.preferredHeight: 36
                            visible: settingsContainer.wallpaperEnabled
                            radius: 6
                            color: browseMouse.containsMouse ? settingsContainer.accentColor : settingsContainer.surfaceColor
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Text {
                                anchors.centerIn: parent
                                text: "browse wallpapers"
                                color: browseMouse.containsMouse ? "#181818" : "#ffffff"
                                font.family: "Torus"
                                font.pixelSize: 12
                                font.bold: true
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }

                            MouseArea {
                                id: browseMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: settingsContainer.openWallpaperPicker()
                            }
                        }

                        // 🍅 the illusion of productivity
                        Text { text: "pomodoro"; color: "#888888"; font.family: "Torus"; font.pixelSize: 11 }

                        RowLayout {
                            Layout.fillWidth: true; spacing: 8
                            Text { text: "work"; color: "#ffffff"; font.family: "Torus"; font.pixelSize: 13 }
                            Item { Layout.fillWidth: true }
                            Rectangle {
                                Layout.preferredWidth: 24; Layout.preferredHeight: 24; radius: 4; color: settingsContainer.surfaceColor
                                Text { anchors.centerIn: parent; text: "\u2212"; color: "#ffffff"; font.pixelSize: 14 }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: settingsContainer.pomodoroWorkDuration = Math.max(1, settingsContainer.pomodoroWorkDuration - 1) }
                            }
                            Text { text: settingsContainer.pomodoroWorkDuration + "m"; font.family: "Torus"; font.pixelSize: 13; font.bold: true; color: settingsContainer.accentColor; horizontalAlignment: Text.AlignHCenter; Layout.preferredWidth: 36 }
                            Rectangle {
                                Layout.preferredWidth: 24; Layout.preferredHeight: 24; radius: 4; color: settingsContainer.surfaceColor
                                Text { anchors.centerIn: parent; text: "+"; color: "#ffffff"; font.pixelSize: 14 }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: settingsContainer.pomodoroWorkDuration = Math.min(120, settingsContainer.pomodoroWorkDuration + 1) }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true; spacing: 8
                            Text { text: "break"; color: "#ffffff"; font.family: "Torus"; font.pixelSize: 13 }
                            Item { Layout.fillWidth: true }
                            Rectangle {
                                Layout.preferredWidth: 24; Layout.preferredHeight: 24; radius: 4; color: settingsContainer.surfaceColor
                                Text { anchors.centerIn: parent; text: "\u2212"; color: "#ffffff"; font.pixelSize: 14 }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: settingsContainer.pomodoroBreakDuration = Math.max(1, settingsContainer.pomodoroBreakDuration - 1) }
                            }
                            Text { text: settingsContainer.pomodoroBreakDuration + "m"; font.family: "Torus"; font.pixelSize: 13; font.bold: true; color: settingsContainer.accentColor; horizontalAlignment: Text.AlignHCenter; Layout.preferredWidth: 36 }
                            Rectangle {
                                Layout.preferredWidth: 24; Layout.preferredHeight: 24; radius: 4; color: settingsContainer.surfaceColor
                                Text { anchors.centerIn: parent; text: "+"; color: "#ffffff"; font.pixelSize: 14 }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: settingsContainer.pomodoroBreakDuration = Math.min(60, settingsContainer.pomodoroBreakDuration + 1) }
                            }
                        }

                        Text { text: "notification popup duration"; color: "#888888"; font.family: "Torus"; font.pixelSize: 11 }

                        RowLayout {
                            Layout.fillWidth: true; spacing: 8
                            Item { Layout.fillWidth: true }
                            Rectangle {
                                Layout.preferredWidth: 24; Layout.preferredHeight: 24; radius: 4; color: settingsContainer.surfaceColor
                                Text { anchors.centerIn: parent; text: "\u2212"; color: "#ffffff"; font.pixelSize: 14 }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: settingsContainer.popupDuration = Math.max(1, settingsContainer.popupDuration - 1) }
                            }
                            Text { text: settingsContainer.popupDuration + "s"; font.family: "Torus"; font.pixelSize: 13; font.bold: true; color: settingsContainer.accentColor; horizontalAlignment: Text.AlignHCenter; Layout.preferredWidth: 36 }
                            Rectangle {
                                Layout.preferredWidth: 24; Layout.preferredHeight: 24; radius: 4; color: settingsContainer.surfaceColor
                                Text { anchors.centerIn: parent; text: "+"; color: "#ffffff"; font.pixelSize: 14 }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: settingsContainer.popupDuration = Math.min(30, settingsContainer.popupDuration + 1) }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                    }
                }

                // audio tab
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: settingsContainer.activeCategory === 1
                    clip: true

                    Flickable {
                        anchors.fill: parent
                        contentHeight: col1.height
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        ColumnLayout {
                            id: col1
                            width: parent.width
                            spacing: 8

                            Text { text: "output"; color: "#888888"; font.family: "Torus"; font.pixelSize: 11 }

                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 8

                            RowLayout {
                                Layout.fillWidth: true; spacing: 8
                                Text { text: "volume"; color: "#ffffff"; font.family: "Torus"; font.pixelSize: 13; Layout.fillWidth: true }
                                Item { Layout.fillWidth: true }
                                Text { text: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio ? Math.round(Pipewire.defaultAudioSink.audio.volume * 100) + "%" : "—"; color: settingsContainer.accentColor; font.family: "Torus"; font.pixelSize: 12; font.bold: true }
                            }

                            Rectangle {
                                Layout.fillWidth: true; height: 24; radius: 4; color: "#2a2a32"; clip: true
                                Rectangle {
                                    height: parent.height; width: parent.width * (Pipewire.defaultAudioSink?.audio?.volume ?? 0); radius: 4; color: settingsContainer.accentColor
                                    Behavior on width { NumberAnimation { duration: 100 } }
                                }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onPositionChanged: (mouse) => { if (pressed && Pipewire.defaultAudioSink?.audio) { var vol = Math.max(0, Math.min(1, mouse.x / width)); Pipewire.defaultAudioSink.audio.volume = vol; } }
                                    onPressed: (mouse) => { if (Pipewire.defaultAudioSink?.audio) { var vol = Math.max(0, Math.min(1, mouse.x / width)); Pipewire.defaultAudioSink.audio.volume = vol; } }
                                }
                            }
                        }

                        Text { text: "scroll step size"; color: "#888888"; font.family: "Torus"; font.pixelSize: 11 }

                        RowLayout {
                            Layout.fillWidth: true; spacing: 8
                            Item { Layout.fillWidth: true }
                            Rectangle {
                                Layout.preferredWidth: 24; Layout.preferredHeight: 24; radius: 4; color: settingsContainer.surfaceColor
                                Text { anchors.centerIn: parent; text: "\u2212"; color: "#ffffff"; font.pixelSize: 14 }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: settingsContainer.volumeStep = Math.max(0.05, settingsContainer.volumeStep - 0.05) }
                            }
                            Text { text: Math.round(settingsContainer.volumeStep * 100) + "%"; font.family: "Torus"; font.pixelSize: 13; font.bold: true; color: settingsContainer.accentColor; horizontalAlignment: Text.AlignHCenter; Layout.preferredWidth: 36 }
                            Rectangle {
                                Layout.preferredWidth: 24; Layout.preferredHeight: 24; radius: 4; color: settingsContainer.surfaceColor
                                Text { anchors.centerIn: parent; text: "+"; color: "#ffffff"; font.pixelSize: 14 }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: settingsContainer.volumeStep = Math.min(0.5, settingsContainer.volumeStep + 0.05) }
                            }
                        }

                        SettingToggle {
                            label: "mute"
                            toggled: Pipewire.defaultAudioSink?.audio?.muted ?? false
                            onUserToggled: (state) => { if (Pipewire.defaultAudioSink?.audio) Pipewire.defaultAudioSink.audio.muted = state; }
                            accentColor: settingsContainer.accentColor
                        }

                        Item { Layout.fillHeight: true }
                    }
                    }
                }

                // notifications tab
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: settingsContainer.activeCategory === 2
                    clip: true

                    Flickable {
                        anchors.fill: parent
                        contentHeight: col2.height
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        ColumnLayout {
                            id: col2
                            width: parent.width
                            spacing: 8

                            Text { text: "notification settings"; color: "#888888"; font.family: "Torus"; font.pixelSize: 11 }

                        SettingToggle {
                            label: "show notification popup"
                            toggled: settingsContainer.showNotifPopup
                            onUserToggled: (val) => settingsContainer.showNotifPopup = val
                            accentColor: settingsContainer.accentColor
                        }
                        SettingToggle {
                            label: "auto-dismiss"
                            toggled: settingsContainer.autoDismiss
                            onUserToggled: (val) => settingsContainer.autoDismiss = val
                            accentColor: settingsContainer.accentColor
                        }

                        Text { text: "max popup notifications"; color: "#888888"; font.family: "Torus"; font.pixelSize: 11 }

                        RowLayout {
                            Layout.fillWidth: true; spacing: 8
                            Item { Layout.fillWidth: true }
                            Rectangle {
                                Layout.preferredWidth: 24; Layout.preferredHeight: 24; radius: 4; color: settingsContainer.surfaceColor
                                Text { anchors.centerIn: parent; text: "\u2212"; color: "#ffffff"; font.pixelSize: 14 }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { var v = settingsContainer.maxPopupNotifs; settingsContainer.maxPopupNotifs = v === 0 ? 50 : Math.max(1, v - 1); } }
                            }
                            Text { text: settingsContainer.maxPopupNotifs === 0 ? "∞" : settingsContainer.maxPopupNotifs; font.family: "Torus"; font.pixelSize: 13; font.bold: true; color: settingsContainer.accentColor; horizontalAlignment: Text.AlignHCenter; Layout.preferredWidth: 36 }
                            Rectangle {
                                Layout.preferredWidth: 24; Layout.preferredHeight: 24; radius: 4; color: settingsContainer.surfaceColor
                                Text { anchors.centerIn: parent; text: "+"; color: "#ffffff"; font.pixelSize: 14 }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { var v = settingsContainer.maxPopupNotifs; settingsContainer.maxPopupNotifs = v >= 50 ? 0 : v + 1; } }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                    }
                }

                // media tab
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: settingsContainer.activeCategory === 3

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 8

                        Text {
                            text: "now playing"
                            color: "#888888"
                            font.family: "Torus"
                            font.pixelSize: 11
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 72
                            radius: 8
                            color: settingsContainer.surfaceColor

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 8

                                Rectangle {
                                    Layout.preferredWidth: 56
                                    Layout.preferredHeight: 56
                                    radius: 6
                                    color: "#2a2a32"

                                    Image {
                                        anchors.fill: parent
                                        anchors.margins: 2
                                        fillMode: Image.PreserveAspectFit
                                        source: activePlayer?.trackArtUrl ?? ""
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    MarqueeText {
                                        Layout.fillWidth: true
                                        height: 20
                                        label: activePlayer?.trackTitle ?? "no media playing"
                                        color: "#ffffff"
                                        fontSize: 13
                                        bold: true
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: activePlayer?.trackArtist ?? ""
                                        color: "#888888"
                                        font.family: "Torus"
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }

                        // playback controls
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Item { Layout.fillWidth: true }

                            MediaButton {
                                text: "󰒮"
                                onClicked: { if (activePlayer) activePlayer.previous() }
                                surfaceColor: settingsContainer.surfaceColor
                                textColor: "#ffffff"
                            }

                            MediaButton {
                                text: activePlayer?.playbackState === MprisPlaybackState.Playing ? "󰏤" : "󰐊"
                                onClicked: {
                                    if (!activePlayer) return;
                                    if (activePlayer.playbackState === MprisPlaybackState.Playing)
                                        activePlayer.pause();
                                    else activePlayer.play();
                                }
                                btnWidth: 42
                                btnHeight: 42
                                radius: 21
                                surfaceColor: settingsContainer.surfaceColor
                                textColor: "#ffffff"
                            }

                            MediaButton {
                                text: "󰒭"
                                onClicked: { if (activePlayer) activePlayer.next() }
                                surfaceColor: settingsContainer.surfaceColor
                                textColor: "#ffffff"
                            }

                            Item { Layout.fillWidth: true }
                        }

                        Text {
                            text: "audio spectrum"
                            color: "#888888"
                            font.family: "Torus"
                            font.pixelSize: 11
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 60

                            PwNodePeakMonitor {
                                id: peakMonitor
                                node: Pipewire.defaultAudioSink
                                enabled: true
                            }

                            Timer {
                                interval: 50
                                running: true
                                repeat: true
                                onTriggered: {
                                    var peak = peakMonitor.peak || 0;
                                    var newVals = [];
                                    for (var i = 0; i < settingsContainer.barCount; i++) {
                                        var freq = i / settingsContainer.barCount;
                                        var factor = 1 - Math.abs(freq - 0.5) * 1.4;
                                        var variation = 0.7 + Math.random() * 0.3;
                                        newVals.push(Math.min(1, peak * factor * variation * 1.5));
                                    }
                                    settingsContainer.barValues = newVals;
                                }
                            }

                            Row {
                                anchors.fill: parent
                                spacing: 8

                                Repeater {
                                    model: settingsContainer.barValues.length

                                    delegate: Rectangle {
                                        required property int index

                                        width: (parent.width - (parent.spacing * (settingsContainer.barValues.length - 1))) / Math.max(1, settingsContainer.barValues.length)
                                        height: parent.height * Math.min(1, (settingsContainer.barValues[index] || 0))
                                        anchors.bottom: parent.bottom
                                        radius: Math.max(1, width / 3)
                                        color: settingsContainer.visColor
                                        Behavior on height { SmoothedAnimation { duration: 60; velocity: 8 } }
                                    }
                                }
                            }
                        }

                        Text {
                            text: "bar count"
                            color: "#888888"
                            font.family: "Torus"
                            font.pixelSize: 11
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Item { Layout.fillWidth: true }

                            Rectangle {
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24
                                radius: 4
                                color: settingsContainer.surfaceColor
                                Text {
                                    anchors.centerIn: parent
                                    text: "\u2212"
                                    color: "#ffffff"
                                    font.pixelSize: 14
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: settingsContainer.barCount = Math.max(4, settingsContainer.barCount - 4)
                                }
                            }

                            Text {
                                text: settingsContainer.barCount
                                font.family: "Torus"
                                font.pixelSize: 13
                                font.bold: true
                                color: settingsContainer.accentColor
                                horizontalAlignment: Text.AlignHCenter
                                Layout.preferredWidth: 36
                            }

                            Rectangle {
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24
                                radius: 4
                                color: settingsContainer.surfaceColor
                                Text {
                                    anchors.centerIn: parent
                                    text: "+"
                                    color: "#ffffff"
                                    font.pixelSize: 14
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: settingsContainer.barCount = Math.min(64, settingsContainer.barCount + 4)
                                }
                            }
                        }

                        SettingToggle {
                            label: "hex input"
                            toggled: settingsContainer.spectrumHexInput
                            onUserToggled: (val) => settingsContainer.spectrumHexInput = val
                            accentColor: settingsContainer.accentColor
                        }

                        ColorRow {
                            label: "spectrum color"
                            selected: settingsContainer.visColor
                            hexMode: settingsContainer.spectrumHexInput
                            colors: ["#ec8fbe", "#ff66aa", "#ff4444", "#ff8844", "#ffcc44", "#88dd44", "#44bb44", "#44ddcc", "#44aaff", "#6688ff", "#aa66ff", "#dd44ff"]
                            onColorPicked: (c) => settingsContainer.visColor = c
                        }

                        SettingToggle {
                            label: "show on bar"
                            toggled: settingsContainer.showMediaDisplay
                            onUserToggled: (val) => settingsContainer.showMediaDisplay = val
                            accentColor: settingsContainer.accentColor
                        }

                        Item { Layout.fillHeight: true }
                    }
                }

                // appearance tab
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: settingsContainer.activeCategory === 4
                    clip: true

                    Flickable {
                        anchors.fill: parent
                        contentHeight: col4.height
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        ColumnLayout {
                            id: col4
                            width: parent.width
                            spacing: 8

                            Text { text: "theme presets"; color: "#888888"; font.family: "Torus"; font.pixelSize: 11 }

                        RowLayout {
                            Layout.fillWidth: true; spacing: 8
                            TextField {
                                id: themeNameField
                                Layout.fillWidth: true
                                Layout.preferredHeight: 28
                                background: Rectangle { radius: 6; color: "#2a2a32"; border.width: 1; border.color: themeNameField.activeFocus ? settingsContainer.accentColor : "#444444" }
                                leftPadding: 8; rightPadding: 8
                                verticalAlignment: TextInput.AlignVCenter
                                color: "#ffffff"; font.family: "Torus"; font.pixelSize: 12
                                placeholderText: "new theme name"
                                placeholderTextColor: "#888888"
                                maximumLength: 24
                            }
                            Rectangle {
                                Layout.preferredWidth: 28; Layout.preferredHeight: 28; radius: 6
                                color: saveMouse.containsMouse ? settingsContainer.accentColor : settingsContainer.surfaceColor
                                Behavior on color { ColorAnimation { duration: 120 } }
                                Text { anchors.centerIn: parent; text: "+"; color: "#ffffff"; font.pixelSize: 16; font.bold: true }
                                MouseArea {
                                    id: saveMouse
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                    onClicked: {
                                        var name = themeNameField.text.trim();
                                        if (!name) return;
                                        for (var i = 0; i < settingsContainer.customThemes.length; i++) {
                                            if (settingsContainer.customThemes[i].name === name) return;
                                        }
                                        settingsContainer.customThemes = settingsContainer.customThemes.concat([{
                                            "name": name,
                                            "accent": settingsContainer.accentColor,
                                            "bg": settingsContainer.bgColor,
                                            "surface": settingsContainer.surfaceColor,
                                            "border": settingsContainer.borderColor,
                                            "activeWs": settingsContainer.activeWsColor
                                        }]);
                                        settingsContainer.saveCustomThemes();
                                        themeNameField.text = "";
                                    }
                                }
                            }
                        }

                        Flow {
                            id: themeFlow; Layout.fillWidth: true; spacing: 4
                            property var builtin: [
                                { "name": "default", "accent": "#ec8fbe", "bg": "#181818", "surface": "#1e1e24", "border": "#333333", "activeWs": "#01eb9d" },
                                { "name": "frappé", "accent": "#f4b8e4", "bg": "#303446", "surface": "#51576d", "border": "#232634", "activeWs": "#a6d189" },
                                { "name": "dracula", "accent": "#ff79c6", "bg": "#282a36", "surface": "#44475a", "border": "#6272a4", "activeWs": "#50fa7b" },
                                { "name": "nord", "accent": "#88c0d0", "bg": "#2e3440", "surface": "#3b4252", "border": "#4c566a", "activeWs": "#a3be8c" },
                                { "name": "tokyo night", "accent": "#f7768e", "bg": "#1a1b26", "surface": "#24283b", "border": "#565f89", "activeWs": "#9ece6a" },
                                { "name": "gruvbox", "accent": "#fe8019", "bg": "#282828", "surface": "#3c3836", "border": "#504945", "activeWs": "#b8bb26" },
                                { "name": "one dark", "accent": "#61afef", "bg": "#282c34", "surface": "#353b45", "border": "#3e4451", "activeWs": "#98c379" }
                            ]

                            Repeater {
                                model: themeFlow.builtin
                                delegate: Item {
                                    required property var modelData
                                    width: 100; height: 44
                                    property var theme: modelData
                                    Rectangle {
                                        anchors.fill: parent; radius: 6; color: settingsContainer.surfaceColor; border.width: 1; border.color: settingsContainer.borderColor
                                        Column {
                                            anchors.centerIn: parent; spacing: 4
                                            Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 20; height: 4; radius: 2; color: theme.accent }
                                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: theme.name; font.family: "Torus"; font.pixelSize: 10; color: "#ffffff" }
                                        }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                settingsContainer.accentColor = theme.accent; settingsContainer.bgColor = theme.bg
                                                settingsContainer.surfaceColor = theme.surface; settingsContainer.borderColor = theme.border
                                                settingsContainer.activeWsColor = theme.activeWs
                                            }
                                        }
                                    }
                                }
                            }

                            Repeater {
                                model: settingsContainer.customThemes
                                delegate: Item {
                                    required property var modelData
                                    required property int index
                                    width: 100; height: 44
                                    property var theme: modelData
                                    Rectangle {
                                        anchors.fill: parent; radius: 6; color: settingsContainer.surfaceColor; border.width: 1;                                         border.color: delMouse.containsMouse ? "#ff4444" : settingsContainer.borderColor
                                        Behavior on border.color { ColorAnimation { duration: 120 } }
                                        Column {
                                            anchors.centerIn: parent; spacing: 4
                                            Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 20; height: 4; radius: 2; color: theme.accent }
                                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: theme.name; font.family: "Torus"; font.pixelSize: 10; color: "#ffffff" }
                                        }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                settingsContainer.accentColor = theme.accent; settingsContainer.bgColor = theme.bg
                                                settingsContainer.surfaceColor = theme.surface; settingsContainer.borderColor = theme.border
                                                settingsContainer.activeWsColor = theme.activeWs
                                            }
                                        }
                                    }
                                    Rectangle {
                                        anchors.top: parent.top; anchors.right: parent.right; anchors.margins: -4
                                        width: 18; height: 18; radius: 9
                                        color: delMouse.containsMouse ? "#ff5580" : "#c31c44"
                                        Behavior on color { ColorAnimation { duration: 120 } }
                                        Text { anchors.centerIn: parent; text: "\u00D7"; color: "#ffffff"; font.pixelSize: 12; font.bold: true }
                                        MouseArea {
                                            id: delMouse
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                            onClicked: {
                                                var arr = settingsContainer.customThemes.slice();
                                                arr.splice(index, 1);
                                                var data = JSON.stringify(arr);
                                                var path = Quickshell.env("HOME") + "/.config/quickshell/lazerbar/custom-themes.json";
                                                customThemeSaver.command = ["sh", "-c", "echo '" + data.replace(/'/g, "'\\''") + "' > '" + path + "'"];
                                                customThemeSaver.running = true;
                                                settingsContainer.customThemes = arr;
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: settingsContainer.borderColor }

                        Text { text: "custom colors"; color: "#888888"; font.family: "Torus"; font.pixelSize: 11 }

                        SettingToggle {
                            label: "hex input"
                            toggled: settingsContainer.hexInput
                            onUserToggled: (val) => settingsContainer.hexInput = val
                            accentColor: settingsContainer.accentColor
                        }

                        ColorRow { label: "accent"; selected: settingsContainer.accentColor; hexMode: settingsContainer.hexInput; colors: ["#ec8fbe", "#ff66aa", "#ff4444", "#ff8844", "#ffcc44", "#88dd44", "#44bb44", "#44ddcc", "#44aaff", "#6688ff", "#aa66ff", "#dd44ff"]; onColorPicked: (c) => settingsContainer.accentColor = c }
                        ColorRow { label: "background"; selected: settingsContainer.bgColor; hexMode: settingsContainer.hexInput; colors: ["#000000", "#111111", "#181818", "#1e1e2e", "#282a36", "#2e3440", "#1a1b26", "#282828"]; onColorPicked: (c) => settingsContainer.bgColor = c }
                        ColorRow { label: "surface"; selected: settingsContainer.surfaceColor; hexMode: settingsContainer.hexInput; colors: ["#1e1e24", "#313244", "#44475a", "#3b4252", "#24283b", "#3c3836", "#2a2a32", "#353535"]; onColorPicked: (c) => settingsContainer.surfaceColor = c }
                        ColorRow { label: "border"; selected: settingsContainer.borderColor; hexMode: settingsContainer.hexInput; colors: ["#333333", "#2a2a2a", "#3d3d3d", "#444444", "#4a4a4a", "#555555", "#5d5d5d", "#666666"]; onColorPicked: (c) => settingsContainer.borderColor = c }
                        ColorRow { label: "active workspace"; selected: settingsContainer.activeWsColor; hexMode: settingsContainer.hexInput; colors: ["#01eb9d", "#ec8fbe", "#ff66aa", "#ff4444", "#ff8844", "#ffcc44", "#88dd44", "#44bb44", "#44ddcc", "#44aaff", "#6688ff", "#aa66ff", "#dd44ff"]; onColorPicked: (c) => settingsContainer.activeWsColor = c }

                        RowLayout {
                            Layout.fillWidth: true; spacing: 8
                            Text { text: "bar transparency"; color: "#888888"; font.family: "Torus"; font.pixelSize: 11 }
                            Item { Layout.fillWidth: true }
                            Text { text: Math.round(settingsContainer.barOpacity * 100) + "%"; color: settingsContainer.accentColor; font.family: "Torus"; font.pixelSize: 12; font.bold: true }
                        }

                        Rectangle {
                            Layout.fillWidth: true; height: 24; radius: 4; color: "#2a2a32"
                            Rectangle { height: parent.height; width: parent.width * settingsContainer.barOpacity; radius: 4; color: settingsContainer.accentColor; Behavior on width { NumberAnimation { duration: 80 } } }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onPositionChanged: (mouse) => { if (pressed) settingsContainer.barOpacity = Math.max(0.3, Math.min(1, mouse.x / width)); }
                                onPressed: (mouse) => { settingsContainer.barOpacity = Math.max(0.3, Math.min(1, mouse.x / width)); }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                    }
                }
            }
        }
    }
}
