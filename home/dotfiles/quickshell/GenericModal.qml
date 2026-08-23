import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"

Scope {
  id: root

  required property var screen

  property string shortcutName: ""

  property alias panelVisible: launcherPanel.visible
  property alias boxWidth: launcherBox.width
  property alias boxHeight: launcherBox.height

  default property alias content: innerContainer.data

  signal opened()
  signal closed()

  function open(): void {
    launcherPanel.visible = true
    contentWrapper.opacity = 1.0
    root.opened()
  }

  function close(): void {
    contentWrapper.opacity = 0.0
    closeTimer.start()
    root.closed()
  }

  function closeAll(): void {
    StateManager.closeAllWidgets()
  }

  function toggle(): void {
    if (launcherPanel.visible) {
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

    Item {
      id: contentWrapper

      anchors.fill: parent
      opacity: 1.0

      Behavior on opacity {
        NumberAnimation {
          duration: Theme.fastAnimation
          easing.type: Easing.InCubic
        }
      }

      // Backdrop
      Rectangle {
        id: backdrop

        anchors.fill: parent

        color: Qt.rgba(0, 0, 0, 0.5)

        MouseArea {
          anchors.fill: parent

          onClicked: {
            root.closeAll()
          }
        }
      }

      // Content
      Rectangle {
        id: launcherBox

        anchors.centerIn: parent

        visible: root.isFocusedMonitor()

        width: launcherPanel.screen
          ? Math.max(
              Theme.widgetMinWidth,
              Math.min(
                Math.round(
                  launcherPanel.screen.width * Theme.widgetWidthRatio
                ),
                Theme.widgetMaxWidth
              )
            )
          : Theme.widgetMaxWidth

        height: Math.min(
          Theme.widgetDefaultHeight,
          Theme.widgetMaxHeight
        )

        radius: Theme.radiusOuter

        color: Theme.colBg

        border.color: Theme.accent1
        border.width: Theme.borderWidth

        MouseArea {
          anchors.fill: parent

          onClicked: {}
        }

        Item {
          id: innerContainer

          anchors.fill: parent
          anchors.margins: 16
        }
      }
    }
  }
}
