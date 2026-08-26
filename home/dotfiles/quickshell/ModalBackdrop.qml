import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import "../"

Scope {
  id: root
  required property var screen
  property string shortcutName: ""
  property bool isVisible: false
  
  default property alias content: focusContainer.data

  signal opened()
  signal closed()

  function open(): void {
    root.isVisible = true
    launcherPanel.visible = true
    root.opened()
  } 

  function close(): void {
    if (!root.isVisible) return
    root.isVisible = false
    closeTimer.start()
    root.closed()
  }

  function closeAll(): void {
    StateManager.closeAllWidgets()
  }

  function toggle(): void {
    if (root.isVisible) {
      close()
    } else {
      open()
    }
  }

  function isFocusedMonitor(): bool {
    const monitor = Hyprland.focusedMonitor
    if (!monitor || !root.screen)
        return false
    return monitor.name === root.screen.name
  }

  Component.onCompleted: {
    StateManager.registerWidget(root)
  }

  Component.onDestruction: {
    StateManager.unregisterWidget(root)
  }

  GlobalShortcut {
    name: root.shortcutName
    onPressed: {
      if (root.shortcutName !== "") {
        root.toggle()
      }
    }
  }

  Timer {
    id: closeTimer
    interval: Theme.fastAnimation + 50
    onTriggered: {
      launcherPanel.visible = false
    }
  }

  PanelWindow {
    id: launcherPanel
    screen: root.screen
    visible: false
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus:
      visible && root.isFocusedMonitor()
        ? WlrKeyboardFocus.Exclusive
        : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-modal"
    exclusionMode: ExclusionMode.Ignore

    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }

    // Close on ESC
    Shortcut {
      sequence: "Escape"
      onActivated: root.closeAll()
    }

    // Dark background to cover monitor
    Rectangle {
      anchors.fill: parent
      color: Qt.rgba(0, 0, 0, 0.35)
      opacity: root.isVisible ? 1.0 : 0.0

      Behavior on opacity {
        NumberAnimation {
          duration: Theme.fastAnimation
          easing.type: Easing.InCubic
        }
      }

      MouseArea {
        anchors.fill: parent
        onClicked: root.closeAll()
      }
    }

    // Inner container, only for focused display
    Item {
      id: focusContainer
      anchors.fill: parent
      visible: root.isFocusedMonitor()
      opacity: root.isVisible ? 1.0 : 0.0
      
      Behavior on opacity {
        NumberAnimation {
          duration: Theme.fastAnimation
          easing.type: Easing.InCubic
        }
      }
    }
  }
}
