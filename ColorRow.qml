import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ColumnLayout {
    id: colorRow

    property string label: ""
    property string selected: "#ffffff"
    property var colors: []
    property bool hexMode: false
    signal colorPicked(string color)

    spacing: 6

    Text {
        text: colorRow.label
        color: "#888888"
        font.family: "Torus"
        font.pixelSize: 11
    }

    Flow {
        Layout.fillWidth: true
        spacing: 6
        visible: !colorRow.hexMode

        Repeater {
            model: colorRow.colors

            delegate: Rectangle {
                width: 28
                height: 28
                radius: 14
                color: modelData

                border.width: colorRow.selected === modelData ? 2.5 : 0
                border.color: "#ffffff"

                Behavior on border.width { NumberAnimation { duration: 100 } }

                Rectangle {
                    width: 6
                    height: 6
                    radius: 3
                    color: "#ffffff"
                    anchors.centerIn: parent
                    opacity: colorRow.selected === modelData ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 100 } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: colorRow.colorPicked(modelData)
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        visible: colorRow.hexMode

        Rectangle {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            radius: 6
            color: colorRow.selected
            border.width: 1
            border.color: "#555555"
        }

        TextField {
            id: hexField
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            background: Rectangle {
                radius: 6
                color: "#2a2a32"
                border.width: 1
                border.color: hexField.activeFocus ? colorRow.selected : "#444444"
            }
            leftPadding: 8
            rightPadding: 8
            verticalAlignment: TextInput.AlignVCenter
            color: "#ffffff"
            font.family: "Torus"
            font.pixelSize: 12
            text: colorRow.selected
            inputMask: "\\#HHHHHH"
            onTextChanged: {
                if (text.length === 7)
                    colorRow.colorPicked(text)
            }
        }
    }
}
