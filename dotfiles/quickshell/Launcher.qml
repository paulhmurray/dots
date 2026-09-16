import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: win
    visible: false
    implicitWidth: 560
    implicitHeight: 420
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property var hidden: ["foot client", "foot server", "avahi", "qt v4l2", "qv4l2"]
    property var apps: DesktopEntries.applications.values
        .filter(a => !hidden.some(h => a.name.toLowerCase().includes(h)))
        .filter(a => !a.noDisplay)
        .sort((a, b) => a.name.localeCompare(b.name))
    property var filtered: apps.filter(a =>
        a.name.toLowerCase().includes(search.text.toLowerCase()))

    IpcHandler {
        target: "launcher"
        function toggle(): void {
            win.visible = !win.visible;
            if (win.visible) {
                search.text = "";
                list.currentIndex = 0;
                search.forceActiveFocus();
            }
        }
    }

    function launch() {
        const entry = filtered[list.currentIndex];
        if (entry) { entry.execute(); win.visible = false; }
    }

    Rectangle {
        anchors.fill: parent
        color: Colours.bg
        border.color: Colours.accent
        border.width: 2
        radius: 10

        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Rectangle {
                width: parent.width
                height: 40
                radius: 6
                color: Colours.surface

                TextInput {
                    id: search
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    verticalAlignment: TextInput.AlignVCenter
                    color: Colours.fg
                    font.family: Colours.font
                    font.pixelSize: 16
                    onTextChanged: list.currentIndex = 0
                    Keys.onDownPressed: list.incrementCurrentIndex()
                    Keys.onUpPressed: list.decrementCurrentIndex()
                    Keys.onReturnPressed: win.launch()
                    Keys.onEscapePressed: win.visible = false
                }
            }

            ListView {
                id: list
                width: parent.width
                height: parent.height - 52
                clip: true
                model: win.filtered
                highlightMoveDuration: 0
                highlight: Rectangle { color: Colours.surface; radius: 6 }

                delegate: Item {
                    required property var modelData
                    required property int index
                    width: list.width
                    height: 36
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        text: modelData.name
                        color: index === list.currentIndex ? Colours.accent : Colours.fg
                        font.family: Colours.font
                        font.pixelSize: 14
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: { list.currentIndex = index; win.launch(); }
                    }
                }
            }
        }
    }
}
