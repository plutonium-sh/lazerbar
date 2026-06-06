import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// app launcher - "i know it's here somewhere" edition
PanelWindow {
    id: appLauncher
    visible: false
    color: "transparent"
    focusable: true

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    // appearance settings wired from parent
    property string surfaceColor: "#1e1e24"
    property string accentColor: "#ec8fbe"
    property string borderColor: "#333333"

    // currently typed search query
    property string query: ""

    // which result is hovered/selected
    property int selectedIndex: -1

    // search results - updated on query change
    property var results: []

    // math evaluation via qalc (libqalculate)
    property string calcResult: ""
    property bool isCalc: false
    property string calcPending: ""

    onQueryChanged: updateResults()

    // debounced qalc process - like end-4 does it
    Process {
        id: qalcProc
        running: false
        stdout: SplitParser {
            onRead: function(data) {
                var trimmed = data.trim();
                if (trimmed.length > 0) {
                    appLauncher.calcResult = trimmed;
                    appLauncher.isCalc = true;
                    appLauncher.showCalcResult(trimmed);
                }
            }
        }
        onExited: function(code) {
            if (code !== 0) appLauncher.isCalc = false;
        }
    }

    Timer {
        id: calcDebounce
        interval: 30
        onTriggered: {
            var expr = appLauncher.calcPending.trim();
            if (!expr) { appLauncher.isCalc = false; return; }
            qalcProc.running = false;
            qalcProc.command = ["qalc", "-t", expr];
            qalcProc.running = true;
        }
    }

    // show math result as an entry in the results list
    function showCalcResult(val) {
        var q = query.trim();
        results = [{ __calc: true, expression: q, result: val }];
    }

    // hyprland global shortcut
    // in hyprland.conf: bind = $mainMod, D, global, quickshell:launcher
    GlobalShortcut {
        name: "launcher"
        onPressed: appLauncher.toggle()
    }

    // resolve an icon to a loadable url
    function iconUrl(name) {
        if (!name) return "";
        var path = Quickshell.iconPath(name, true);
        if (!path || path === "") return "";
        // iconPath returns a QUrl; avoid double-scheme
        return path.toString();
    }

    function updateResults() {
        var de = DesktopEntries;
        var apps = de ? de.applications.values : [];

        var q = query.toLowerCase().trim();
        if (!q) { results = []; return; }

        var matches = [];
        var len = apps ? apps.length : 0;

        for (var i = 0; i < len; i++) {
            var app = apps[i];
            if (!app || !app.name) continue;
            var name = app.name.toLowerCase();
            if (name.includes(q)) {
                var score = 0;
                if (name === q) score = 3;
                else if (name.startsWith(q)) score = 2;
                else if (name.indexOf(" " + q) !== -1) score = 1;
                matches.push({ app: app, score: score });
            }
        }

        matches.sort(function(a, b) {
            if (a.score !== b.score) return b.score - a.score;
            return a.app.name.localeCompare(b.app.name);
        });

        results = matches.slice(0, 20);

        // trigger qalc for math
        if (q && matches.length === 0) {
            appLauncher.calcPending = q;
            calcDebounce.restart();
        } else {
            appLauncher.isCalc = false;
        }
    }

    // opens the launcher with fresh state
    function toggle() {
        appLauncher.visible = !appLauncher.visible;
        if (appLauncher.visible) {
            appLauncher.query = "";
            appLauncher.selectedIndex = -1;
            searchInput.forceActiveFocus();
        }
    }

    // launch the selected app
    function launchApp(app) {
        if (app && app.execute) {
            app.execute();
        } else if (app && app.command) {
            Quickshell.execDetached({ command: ["sh", "-c", app.command.join(" ")] });
        }
        appLauncher.visible = false;
    }

    // navigate results with keyboard
    function selectNext() {
        if (results.length === 0) return;
        selectedIndex = (selectedIndex + 1) % results.length;
    }
    function selectPrev() {
        if (results.length === 0) return;
        selectedIndex = selectedIndex <= 0 ? results.length - 1 : selectedIndex - 1;
    }

    // the void
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha("#000000", 0.88)

        // center column - search up top, results below
        ColumnLayout {
            anchors {
                top: parent.top
                horizontalCenter: parent.horizontalCenter
                topMargin: 180
            }
            width: 600
            spacing: 0

            // search bar - the oracle
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 64
                radius: 16
                color: appLauncher.surfaceColor
                border.width: searchInput.activeFocus ? 2 : 1
                border.color: searchInput.activeFocus ? appLauncher.accentColor : appLauncher.borderColor
                Behavior on border.color { ColorAnimation { duration: 120 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    spacing: 12

                    Image {
                        source: `file://${Quickshell.env("HOME")}/.config/quickshell/lazerbar/assets/search.png`
                        sourceSize.width: 22
                        sourceSize.height: 22
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        color: "#ffffff"
                        font.family: "Torus"
                        font.pixelSize: 20
                        font.bold: true
                        clip: true
                        verticalAlignment: TextInput.AlignVCenter
                        selectByMouse: true

                        Keys.enabled: true

                        onTextChanged: {
                            appLauncher.query = text;
                            appLauncher.selectedIndex = -1;
                        }

                        Keys.onEscapePressed: appLauncher.visible = false
                        Keys.onUpPressed: appLauncher.selectPrev()
                        Keys.onDownPressed: appLauncher.selectNext()
                        Keys.onReturnPressed: {
                            if (appLauncher.selectedIndex < 0 || appLauncher.selectedIndex >= appLauncher.results.length) return;
                            var sel = appLauncher.results[appLauncher.selectedIndex];
                            if (sel && sel.__calc) {
                                Quickshell.execDetached({ command: ["sh", "-c", "wl-copy " + sel.result] });
                            } else if (sel && sel.app) {
                                appLauncher.launchApp(sel.app);
                            }
                        }
                    }

                    // clear button
                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        radius: 14
                        color: clearMouse.containsMouse ? Qt.alpha(appLauncher.accentColor, 0.3) : "transparent"
                        visible: appLauncher.query.length > 0

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: "#888888"
                            font.pixelSize: 14
                        }

                        MouseArea {
                            id: clearMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                searchInput.text = "";
                                searchInput.forceActiveFocus();
                            }
                        }
                    }
                }
            }

            // results - the fruits of your typing labor
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(appLauncher.results.length * 56, 400)
                Layout.topMargin: 12
                clip: true

                ListView {
                    id: resultsList
                    anchors.fill: parent
                    model: appLauncher.results.length
                    spacing: 4
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Item {
                        required property int index
                        width: resultsList.width
                        height: 56

                        property var appData: appLauncher.results[index]
                        property bool isCalc: appData !== undefined && appData !== null && appData.__calc === true

                        Rectangle {
                            anchors.fill: parent
                            radius: 12
                            color: {
                                if (appLauncher.selectedIndex === index) return Qt.alpha(appLauncher.accentColor, 0.25);
                                if (resMouse.containsMouse) return Qt.alpha(appLauncher.accentColor, 0.12);
                                return "transparent";
                            }
                            Behavior on color { ColorAnimation { duration: 80 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                spacing: 16

                                // icon - calc icon for math, app icon for everything else
                                Image {
                                    id: appIcon
                                    Layout.preferredWidth: 36
                                    Layout.preferredHeight: 36
                                    source: isCalc
                                        ? `file://${Quickshell.env("HOME")}/.config/quickshell/lazerbar/assets/search.png`
                                        : (appData && appData.app ? iconUrl(appData.app.icon) : "")
                                    smooth: true
                                    sourceSize.width: 36
                                    sourceSize.height: 36
                                    fillMode: Image.PreserveAspectFit
                                }

                                // fallback when the icon fairy didn't show up
                                Rectangle {
                                    Layout.preferredWidth: 36
                                    Layout.preferredHeight: 36
                                    radius: 8
                                    color: appLauncher.surfaceColor
                                    visible: !isCalc && (!appIcon.source || appIcon.status !== Image.Ready)

                                    Text {
                                        anchors.centerIn: parent
                                        text: appData && appData.app && appData.app.name ? appData.app.name.charAt(0).toUpperCase() : "?"
                                        color: "#888888"
                                        font.family: "Torus"
                                        font.bold: true
                                        font.pixelSize: 16
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        Layout.fillWidth: true
                                        text: isCalc ? appData.expression + " = " + appData.result : (appData && appData.app ? appData.app.name : "")
                                        color: "#ffffff"
                                        font.family: "Torus"
                                        font.pixelSize: 16
                                        font.bold: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: isCalc ? "click or enter to copy" : (appData && appData.app ? (appData.app.comment || appData.app.genericName || "") : "")
                                        color: "#888888"
                                        font.family: "Torus"
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                        visible: text.length > 0
                                    }
                                }

                                // calc result badge
                                Rectangle {
                                    Layout.preferredWidth: 56
                                    Layout.preferredHeight: 32
                                    radius: 8
                                    color: Qt.alpha(appLauncher.accentColor, 0.2)
                                    visible: isCalc

                                    Text {
                                        anchors.centerIn: parent
                                        text: isCalc && appData ? appData.result : ""
                                        color: appLauncher.accentColor
                                        font.family: "Torus"
                                        font.pixelSize: 16
                                        font.bold: true
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: resMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: appLauncher.selectedIndex = index
                            onClicked: {
                                if (isCalc && appData) {
                                    Quickshell.execDetached({ command: ["sh", "-c", "wl-copy " + appData.result] });
                                } else if (appData && appData.app) {
                                    appLauncher.launchApp(appData.app);
                                }
                            }
                        }
                    }
                }
            }

            // empty state - when nobody's home
            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                Layout.topMargin: 40
                text: appLauncher.query.length > 0 ? "no apps found" : "start typing to search apps"
                color: "#555555"
                font.family: "Torus"
                font.pixelSize: 14
                visible: appLauncher.results.length === 0 && !appLauncher.isCalc
            }
        }

        // click outside to close
        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: appLauncher.visible = false
        }
    }
}
