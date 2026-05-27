import QtQuick
import QtQuick.Layouts

Item {
    id: toggleRoot

    property string label: ""
    property bool toggled: false
    property string accentColor: "#ec8fbe"
    signal userToggled(bool val)

    Layout.fillWidth: true
    height: 32

    RowLayout {
        anchors.fill: parent
        spacing: 10

        Text {
            text: toggleRoot.label
            color: "#cccccc"
            font.family: "Torus"
            font.pixelSize: 13
            Layout.fillWidth: true
        }

        Item {
            Layout.preferredWidth: 56
            Layout.preferredHeight: 16
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                anchors.centerIn: parent
                width: toggleRoot.toggled ? 56 : 48
                height: 16
                radius: height / 2
                color: toggleRoot.toggled ? toggleRoot.accentColor : "transparent"
                border.width: toggleRoot.toggled ? 0 : 1.5
                border.color: "#777777"

                Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on border.width { NumberAnimation { duration: 120 } }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        toggleRoot.toggled = !toggleRoot.toggled;
                        toggleRoot.userToggled(toggleRoot.toggled);
                    }
                }
            }
        }
    }
}
