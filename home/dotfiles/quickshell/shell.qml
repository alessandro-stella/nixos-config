import Quickshell
import Quickshell.Wayland
import QtQuick
import "./top_bar/"
import "./app_launcher/"
import "./clipboard/"

ShellRoot {
    // Top bar
    // Variants {
    //     model: Quickshell.screens
    //
    //     TopBar {
    //         modelData: modelData
    //     }
    // }

    // App launcher
    AppLauncher {
        id: appLauncher
    }

    // Clipboard 
    Clipboard {
        id: cliboard
    }
}
