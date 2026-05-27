import QtQuick

Item {
    id: root
    clip: true

    property string label: ""
    property color color: "#ffffff"
    property int fontSize: 13
    property bool bold: false

    Text {
        id: scrollText
        text: root.label
        color: root.color
        font.pixelSize: root.fontSize
        font.family: "Torus"
        font.bold: root.bold
        font.weight: root.bold ? Font.DemiBold : Font.Normal

        x: parent.width - contentWidth

        SequentialAnimation {
            running: scrollText.contentWidth > parent.width
            loops: Animation.Infinite

            PauseAnimation { duration: 3000 }

            NumberAnimation {
                target: scrollText
                property: "x"
                from: parent.width - scrollText.contentWidth
                to: 0
                duration: Math.max(2000, scrollText.contentWidth * 18)
                easing.type: Easing.InOutQuad
            }

            PauseAnimation { duration: 3000 }

            NumberAnimation {
                target: scrollText
                property: "x"
                from: 0
                to: parent.width - scrollText.contentWidth
                duration: Math.max(2000, scrollText.contentWidth * 18)
                easing.type: Easing.InOutQuad
            }
        }

        states: State {
            name: "paused"
            when: !(scrollText.contentWidth > parent.width)
            PropertyChanges { target: scrollText; x: 0 }
        }
    }
}
