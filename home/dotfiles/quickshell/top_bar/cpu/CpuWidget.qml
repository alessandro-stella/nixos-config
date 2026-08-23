import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../"

Rectangle {
  id: root

  required property PanelWindow parentWindow

  implicitWidth: contentRow.implicitWidth
  implicitHeight: parent.height
  color: "transparent"

  property real cpuUsage: 0.0
  
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

  RowLayout {
    id: contentRow
    anchors.centerIn: parent
    spacing: 4

    Text {
      text: " " + Math.round(root.cpuUsage * 100) + "%"
      font.pixelSize: Theme.barFontSize
      font.family: Theme.fontFamily
      color: Theme.barColor
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
