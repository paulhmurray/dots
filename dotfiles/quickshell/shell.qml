import Quickshell
import Quickshell.Io

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
    Keybinds {}
    MusicPanel {}

    IpcHandler {
        target: "pomodoro"
        function toggle(): void { Pomodoro.toggle(); }
        function reset(): void { Pomodoro.reset(); }
    }
}
