import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../"

Rectangle {
  id: root

  required property PanelWindow parentWindow

  implicitWidth: content.implicitWidth
  implicitHeight: parent.height
  color: "transparent"

  property real cpuUsage: 0.0
  readonly property real criticalUsage: 0.80
  
  // CPU usage variables
  property real lastTotal: 0
  property real lastIdle: 0

  Timer {
    interval: 2000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: readCpu.running = true
  }

  // Total CPU usage
  Process {
    id: readCpu
    command: ["sh", "-c", "awk '/^cpu / {printf \"%s,%s\", $2+$3+$4+$5+$6+$7+$8, $5+$6}' /proc/stat"]
    stdout: SplitParser {
      onRead: data => {
        if (!data) return;
        let parts = data.trim().split(",");
        if (parts.length === 2) {
          let total = parseFloat(parts[0]);
          let idle = parseFloat(parts[1]);

          if (root.lastTotal > 0) {
            let totalDiff = total - root.lastTotal;
            let idleDiff = idle - root.lastIdle;
            if (totalDiff > 0) {
              root.cpuUsage = (totalDiff - idleDiff) / totalDiff;
            }
          }
          root.lastTotal = total;
          root.lastIdle = idle;
        }
      }
    }
  }

  Text {
    id: content
    anchors.centerIn: parent
    text: ""
    font.pixelSize: Theme.barFontSize
    font.family: Theme.fontFamily
    color: root.cpuUsage >= root.criticalUsage ? Theme.colRed : Theme.barColor
  }

  // Hover tooltip
  PopupWindow {
    id: hoverPopup
    
    anchor.window: root.parentWindow
    anchor.item: root
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom

    visible: mouseArea.containsMouse || tooltipRect.opacity > 0
    color: "transparent"  

    implicitWidth: tooltipRect.implicitWidth
    implicitHeight: tooltipRect.implicitHeight + Math.round(Theme.outerSpacing / 2)

    Rectangle {
      id: tooltipRect
      color: Theme.widgetDarkBackground
      border.color: Theme.accent1
      border.width: Theme.borderWidth
      radius: 6
      implicitWidth: cpuTooltip.implicitWidth + 24
      implicitHeight: 36
      
      anchors.bottom: parent.bottom
      anchors.horizontalCenter: parent.horizontalCenter

      opacity: mouseArea.containsMouse ? 1 : 0
      scale: mouseArea.containsMouse ? 1 : 0.94

      Behavior on opacity {
        NumberAnimation {
          duration: Theme.fastAnimation
          easing.type: Easing.OutCubic
        }
      }

      Behavior on scale {
        NumberAnimation {
          duration: Theme.fastAnimation
          easing.type: Easing.OutCubic
        }
      }

      Text {
        id: cpuTooltip
        anchors.centerIn: parent
        text: "Total CPU usage: " + Math.round(root.cpuUsage * 100) + "%"
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.barColor
      }
    }
  }

  CpuPopup {
    id: cpuPopup
    parentWindow: root.parentWindow
    targetItem: root
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: cpuPopup.toggle()
  }
}
