import QtQuick

Rectangle {
    id: btn

    property string text: ""
    signal clicked()
    property int btnWidth: 32
    property int btnHeight: 32
    property int btnRadius: 16
    property string surfaceColor: "#1e1e24"
    property string hoverColor: "#2a2a32"
    property string textColor: "#ffffff"

    width: btn.btnWidth
    height: btn.btnHeight
    radius: btn.btnRadius
    color: mouse.containsMouse ? btn.hoverColor : btn.surfaceColor
    Behavior on color { ColorAnimation { duration: 120 } }

    Text {
        anchors.centerIn: parent
        text: btn.text
        color: btn.textColor
        font.pixelSize: btn.btnWidth > 36 ? 18 : 14
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}
