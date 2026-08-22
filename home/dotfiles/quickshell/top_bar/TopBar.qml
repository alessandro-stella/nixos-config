import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../" // Import Theme

// Widgets
import "./battery"
import "./cpu"

PanelWindow {
  id: root
  required property int monitorId
  required property var modelData

  screen: modelData

  anchors {
    top: true
    left: true
    right: true
  }

  implicitHeight: Theme.barHeight
  color: "transparent"

  readonly property color background: Theme.barBackground
  
  // Main bar container
  Rectangle {
    anchors.fill: parent
    color: root.background

    RowLayout {
      anchors.fill: parent

      // Left
      Item { 
        Layout.fillWidth: true
        Layout.fillHeight: true

        RowLayout {
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          anchors.left: parent.left
          spacing: 0

          // Left widgets
          LogoWidget {
            Layout.fillHeight: true
            Layout.preferredWidth: Theme.barHeight 
          }

          WorkspacesWidget {
            currentMonitorId: root.monitorId
            showOnlyCurrentMonitor: true
          }
        }
      }

      // Center
      ClockWidget {}     

      // Right
      Item { 
        Layout.fillWidth: true
        Layout.fillHeight: true

        RowLayout {
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          anchors.right: parent.right

          // Right widgets
          NotificationWidget {
            parentWindow: root
          }

          BatteryWidget {
            parentWindow: root
          }
          
          CpuWidget {
            parentWindow: root
          }
        }
      } 
    }
  }
}
