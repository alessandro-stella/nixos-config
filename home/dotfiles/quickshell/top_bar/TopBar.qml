import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../"

// Widgets
import "./battery"
import "./cpu"
import "./temperature"
import "./audio"
import "./network"

PanelWindow {
  id: root

  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  WlrLayershell.namespace: "quickshell-topbar"
  WlrLayershell.exclusiveZone: Theme.barHeight
  
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
  readonly property int horizontalPadding: Theme.outerSpacing + 1
  readonly property int smallInnerSpacing: 10
  readonly property int bigInnerSpacing: 16
  
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

          anchors.leftMargin: root.horizontalPadding
          spacing: root.smallInnerSpacing

          // Left widgets

          LogoWidget {
            Layout.fillHeight: true
            distroLogo: ""
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
          anchors.rightMargin: root.horizontalPadding 
          spacing: root.bigInnerSpacing

          // Right widgets
          
          NotificationWidget {
            parentWindow: root
          }

          TemperatureWidget {
            parentWindow: root
          }

          CpuWidget {
            parentWindow: root
          }


          NetworkWidget {
            parentWindow: root
          }

          AudioWidget {
            parentWindow: root
          }

          BatteryWidget {
            parentWindow: root
          }          
        }
      } 
    }
  }
}
