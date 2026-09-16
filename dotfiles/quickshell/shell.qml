import Quickshell

ShellRoot {
    Variants {
        model: Quickshell.screens
        Bar {
            required property var modelData
            screen: modelData
        }
    }
    Launcher {}
    Dashboard {}
    Osd {}
    Themes {}
}
