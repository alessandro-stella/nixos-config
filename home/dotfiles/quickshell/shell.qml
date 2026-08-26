import Quickshell
import Quickshell.Wayland
import QtQuick

import "./top_bar/"
import "./app_launcher/"
import "./clipboard/"
import "./logout_menu/"
import "./theme_changer/"

ShellRoot {
  id: root
  
  property var monitorModel: Quickshell.screens.length > 0
    ? [...Array(Quickshell.screens.length)].map((_, i) => i)
    : []

  // Top bar
  Variants {
    model: root.monitorModel

    TopBar {
      monitorId: modelData
      screen: Quickshell.screens[modelData]
    }
  }

  // App launcher
  Variants {
    model: root.monitorModel

    AppLauncher {
      monitorId: modelData
      screen: Quickshell.screens[modelData]
    }
  }

  // Clipboard
  Variants {
    model: root.monitorModel

    Clipboard {
      monitorId: modelData
      screen: Quickshell.screens[modelData]
    }
  }

  // Logout menu
  Variants {
    model: root.monitorModel

    LogoutMenu {
      monitorId: modelData
      screen: Quickshell.screens[modelData]
    }
  }

  // Theme changer
  Variants {
    model: root.monitorModel

    ThemeChanger {
      monitorId: modelData
      screen: Quickshell.screens[modelData]
    }
  }

  // Create new theme modal
  Variants {
    model: root.monitorModel

    CreateNewTheme {
      monitorId: modelData
      screen: Quickshell.screens[modelData]
    }
  }
}
