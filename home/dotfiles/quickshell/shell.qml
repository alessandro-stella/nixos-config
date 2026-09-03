import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

import "./top_bar/"
import "./app_launcher/"
import "./clipboard/"
import "./logout_menu/"
import "./theme_changer/"
import "./lockscreen/"

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

  // Blocks Hyprland's own keybinds while a ModalBackdrop-based widget
  Process {
    id: enterShortcutBlockSubmap
    command: ["bash", "-c", "hyprctl dispatch 'hl.dsp.submap(\"quickshell-lock\")'"]
  }

  Process {
    id: exitShortcutBlockSubmap
    command: ["bash", "-c", "hyprctl dispatch 'hl.dsp.submap(\"reset\")'"]
  }

  Connections {
    target: StateManager
    function onShortcutBlockRequested() { enterShortcutBlockSubmap.running = true }
    function onShortcutBlockReleased() { exitShortcutBlockSubmap.running = true }
  }

  // Lockscreen
  GlobalShortcut {
    name: "toggleLockscreen"
    onPressed: StateManager.toggleLockscreen()
  }

  Variants {
    model: root.monitorModel

    Lockscreen {
      monitorId: modelData
      screen: Quickshell.screens[modelData]
    }
  }
}
