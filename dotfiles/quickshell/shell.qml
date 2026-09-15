import Quickshell
import Quickshell.Hyprland
import QtQuick

ShellRoot {
    SystemClock { id: clock; precision: SystemClock.Minutes }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            anchors { top: true; left: true; right: true }
            implicitHeight: 30
            color: "#1e1e2e"

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                Repeater {
                    model: Hyprland.workspaces
                    Text {
                        required property var modelData
                        text: modelData.id
                        color: modelData.active ? "#cba6f7" : "#6c7086"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: Qt.formatDateTime(clock.date, "ddd d MMM  HH:mm")
                color: "#cdd6f4"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
            }
        }
    }
}
