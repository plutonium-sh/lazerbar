import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

// wallpaper panel - front and center, as god intended
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
    readonly property string cacheDir: home + "/.config/quickshell/lazerbar/wallpapers"
    readonly property string wallpaperJson: home + "/.config/quickshell/lazerbar/wallpapers/wallpapers.json"

    // unprivileged background noise, don't mind me
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "quickshell:background"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // the void stares back (until a wallpaper loads)
    Rectangle {
        anchors.fill: parent
        color: "#181818"
    }

    // the main event, stretched to fit your life
    Image {
        id: bgImg
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        source: root.currentSrc
    }

    // dramatic fade-to-black for smooth transitions (tm)
    Rectangle {
        id: fadeOverlay
        anchors.fill: parent
        color: "#181818"
        opacity: 0.0
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    }

    // no-nonsense wallpaper mode: cut the middleman
    function setDirect(filePath) {
        fadeOverlay.opacity = 1.0;
        swapTimer.filePath = "file://" + filePath.split('/').map(encodeURIComponent).join('/');
        swapTimer.start();
        saveWallpaperJson(filePath);
    }

    // glorified echo command with delusions of grandeur
    Process {
        id: jsonWriter
        running: false
    }

    // reading yesterday's homework and praying it's right
    Process {
        id: jsonReader
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text.trim());
                    if (data.current && root.enabled) {
                        root.savedWallpaper = data.current;
                        root.setDirect(data.current);
                    }
                } catch (e) {}
            }
        }
    }

    // the world's most overqualified wallpaper saver
    function saveWallpaperJson(filePath) {
        root.savedWallpaper = filePath;
        var data = JSON.stringify({"current": filePath});
        var sanitized = data.replace(/'/g, "'\\''");
        jsonWriter.command = ["sh", "-c", "echo '" + sanitized + "' > " + root.wallpaperJson];
        jsonWriter.running = true;
    }

    function loadWallpaperJson() {
        jsonReader.command = ["cat", root.wallpaperJson];
        jsonReader.running = true;
    }

    // 220ms of suspense -- will it blend?
    Timer {
        id: swapTimer
        property string filePath: ""
        interval: 220
        repeat: false
        onTriggered: {
            root.currentSrc = filePath;
            fadeOverlay.opacity = 0.0;
        }
    }

    // wallpaper existential crisis handler
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
