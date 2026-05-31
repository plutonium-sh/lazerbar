import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root
    anchors { left: true; right: true; top: true; bottom: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    visible: root.enabled

    property bool enabled: true
    property string currentSrc: ""
    property string savedWallpaper: ""

    readonly property string home: Quickshell.env("HOME")
    readonly property string configDir: home + "/.config/quickshell/lazerbar"
    readonly property string cacheDir: configDir + "/wallpapers"
    readonly property string wallpaperJson: configDir + "/wallpapers.json"

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "quickshell:background"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Rectangle {
        anchors.fill: parent
        color: "#181818"
    }

    Image {
        id: bgImg
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        source: root.currentSrc
    }

    Rectangle {
        id: fadeOverlay
        anchors.fill: parent
        color: "#181818"
        opacity: 0.0
    }

    PropertyAnimation {
        id: fadeOut
        target: fadeOverlay
        property: "opacity"
        from: 1.0
        to: 0.0
        duration: 350
        easing.type: Easing.OutCubic
    }

    property bool pendingFade: false

    function setDirect(filePath) {
        fadeOverlay.opacity = 1.0
        pendingFade = true
        root.currentSrc = "file://" + filePath.split('/').map(encodeURIComponent).join('/')
        saveWallpaperJson(filePath)
        minTimer.restart()
    }

    Timer {
        id: minTimer
        interval: 200
        onTriggered: tryFade()
    }

    function tryFade() {
        if (bgImg.status === Image.Ready || bgImg.status === Image.Error) {
            pendingFade = false
            fadeOut.start()
        }
    }

    Connections {
        target: bgImg
        function onStatusChanged() {
            if (pendingFade && !minTimer.running && !fadeOut.running && (bgImg.status === Image.Ready || bgImg.status === Image.Error)) {
                pendingFade = false
                fadeOut.start()
            }
        }
    }

    Process {
        id: jsonWriter
        running: false
    }

    Process {
        id: jsonReader
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text.trim());
                    if (data.current && root.enabled) {
                        var fullPath = data.current.startsWith("/") ? data.current : root.configDir + "/" + data.current;
                        root.savedWallpaper = fullPath;
                        root.setDirect(fullPath);
                    }
                } catch (e) {}
            }
        }
    }

    function saveWallpaperJson(filePath) {
        root.savedWallpaper = filePath;
        var relPath = filePath.startsWith(root.configDir + "/") ? filePath.substring(root.configDir.length + 1) : filePath;
        var data = JSON.stringify({"current": relPath});
        var sanitized = data.replace(/'/g, "'\\''");
        jsonWriter.command = ["sh", "-c", "echo '" + sanitized + "' > " + root.wallpaperJson];
        jsonWriter.running = true;
    }

    function loadWallpaperJson() {
        jsonReader.command = ["cat", root.wallpaperJson];
        jsonReader.running = true;
    }

    onEnabledChanged: {
        if (root.enabled) {
            if (root.savedWallpaper) {
                root.setDirect(root.savedWallpaper);
            } else {
                root.loadWallpaperJson();
            }
        } else {
            root.currentSrc = "";
        }
    }

    Component.onCompleted: root.loadWallpaperJson()
}
