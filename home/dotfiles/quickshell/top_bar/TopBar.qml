import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../"
import "./battery"

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
  //
  // Main bar container
  Rectangle {
    anchors.fill: parent
    color: root.background

    RowLayout {
      anchors.fill: parent
      spacing: 0

      // Left
      Item { 
        Layout.fillWidth: true
        Layout.fillHeight: true

        RowLayout {
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          anchors.left: parent.left
          anchors.leftMargin: 10
          spacing: 10

          // Left widgets
          LogoWidget {}

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
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          anchors.rightMargin: 10
          spacing: 8

          // Right widgets
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
