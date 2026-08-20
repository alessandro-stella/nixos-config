import Quickshell
import Quickshell.Wayland
import QtQuick
import "./top_bar/"
import "./app_launcher/"
import "./clipboard/"

ShellRoot {
  // Top bar
  Variants {
    model: Quickshell.screens.length > 0 ? 
      [...Array(Quickshell.screens.length)].map((_, i) => ({
        index: i,
        screen: Quickshell.screens[i]
      })) : []
    
    TopBar {
      monitorId: modelData.index
      screen: modelData.screen
    }
  }

  // App launcher
  AppLauncher {
    id: appLauncher
  }

  // Clipboard 
  Clipboard {
    id: cliboard
  }
}
