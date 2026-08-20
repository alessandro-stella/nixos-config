import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../"

PanelWindow {
  id: root

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

  // Metriche CPU
  property int cpuUsage: 0
  property var lastCpuIdle: 0
  property var lastCpuTotal: 0

  // Lettura statistiche CPU da /proc/stat
  Process {
    id: cpuProc
    command: ["sh", "-c", "head -n1 /proc/stat"]
    running: true
    stdout: SplitParser {
      onRead: data => {
        if (!data || data.trim() === "") return
        const parts = data.trim().split(/\s+/)

        const user = parseInt(parts[1]) || 0
        const nice = parseInt(parts[2]) || 0
        const system = parseInt(parts[3]) || 0
        const idle = parseInt(parts[4]) || 0
        const iowait = parseInt(parts[5]) || 0
        const irq = parseInt(parts[6]) || 0
        const softirq = parseInt(parts[7]) || 0

        const total = user + nice + system + idle + iowait + irq + softirq
        const idleTime = idle + iowait

        if (root.lastCpuTotal > 0) {
          const totalDiff = total - root.lastCpuTotal
          const idleDiff = idleTime - root.lastCpuIdle
          if (totalDiff > 0) {
            root.cpuUsage = Math.max(0, Math.min(100, Math.round(100 * (totalDiff - idleDiff) / totalDiff)))
          }
        }
        root.lastCpuTotal = total
        root.lastCpuIdle = idleTime
      }
    }
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: cpuProc.running = true
  }

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
          WorkspacesWidget {}
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
            usage: root.cpuUsage
          }
        }
      } 
    }
  }
}
