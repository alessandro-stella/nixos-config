import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "../"

PanelWindow {
  id: topBar

  required property var modelData
  screen: modelData

  anchors {
    top: true
    left: true
    right: true
  }

  implicitHeight: 30
  color: Theme.colBg 

  margins {
    top: 0
    bottom: 0
    left: 0
    right: 0
  }

  // ===== PROPRIETÀ SISTEMA =====
  property string kernelVersion: "Linux"
  property int cpuUsage: 0
  property int memUsage: 0
  property int diskUsage: 0
  property int volumeLevel: 0
  property string activeWindow: "Window"
  property string currentLayout: "Tile"
  property var lastCpuIdle: 0
  property var lastCpuTotal: 0

  // ===== PROCESSI =====
  Process {
    id: kernelProc
    command: ["uname", "-r"]
    stdout: SplitParser {
      onRead: data => {
        if (data) topBar.kernelVersion = data.trim()
      }
    }
    Component.onCompleted: running = true
  }

  Process {
    id: cpuProc
    command: ["sh", "-c", "head -1 /proc/stat"]
    stdout: SplitParser {
      onRead: data => {
        if (!data) return
        var parts = data.trim().split(/\s+/)
        var user = parseInt(parts[1]) || 0
        var nice = parseInt(parts[2]) || 0
        var system = parseInt(parts[3]) || 0
        var idle = parseInt(parts[4]) || 0
        var iowait = parseInt(parts[5]) || 0
        var irq = parseInt(parts[6]) || 0
        var softirq = parseInt(parts[7]) || 0

        var total = user + nice + system + idle + iowait + irq + softirq
        var idleTime = idle + iowait

        if (topBar.lastCpuTotal > 0) {
          var totalDiff = total - topBar.lastCpuTotal
          var idleDiff = idleTime - topBar.lastCpuIdle
          if (totalDiff > 0) {
            topBar.cpuUsage = Math.round(100 * (totalDiff - idleDiff) / totalDiff)
          }
        }
        topBar.lastCpuTotal = total
        topBar.lastCpuIdle = idleTime
      }
    }
    Component.onCompleted: running = true
  }

  Process {
    id: memProc
    command: ["sh", "-c", "free | grep Mem"]
    stdout: SplitParser {
      onRead: data => {
        if (!data) return
        var parts = data.trim().split(/\s+/)
        var total = parseInt(parts[1]) || 1
        var used = parseInt(parts[2]) || 0
        topBar.memUsage = Math.round(100 * used / total)
      }
    }
    Component.onCompleted: running = true
  }

  Process {
    id: diskProc
    command: ["sh", "-c", "df / | tail -1"]
    stdout: SplitParser {
      onRead: data => {
        if (!data) return
        var parts = data.trim().split(/\s+/)
        var percentStr = parts[4] || "0%"
        topBar.diskUsage = parseInt(percentStr.replace('%', '')) || 0
      }
    }
    Component.onCompleted: running = true
  }

  Process {
    id: volProc
    command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
    stdout: SplitParser {
      onRead: data => {
        if (!data) return
        var match = data.match(/Volume:\s*([\d.]+)/)
        if (match) {
          topBar.volumeLevel = Math.round(parseFloat(match[1]) * 100)
        }
      }
    }
    Component.onCompleted: running = true
  }

  Process {
    id: windowProc
    command: ["sh", "-c", "hyprctl activewindow -j | jq -r '.title // empty'"]
    stdout: SplitParser {
      onRead: data => {
        if (data && data.trim()) {
          topBar.activeWindow = data.trim()
        }
      }
    }
    Component.onCompleted: running = true
  }

  Process {
    id: layoutProc
    command: ["sh", "-c", "hyprctl activewindow -j | jq -r 'if .floating then \"Floating\" elif .fullscreen == 1 then \"Fullscreen\" else \"Tiled\" end'"]
    stdout: SplitParser {
      onRead: data => {
        if (data && data.trim()) {
          topBar.currentLayout = data.trim()
        }
      }
    }
    Component.onCompleted: running = true
  }

  // ===== TIMER =====
  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: {
      cpuProc.running = true
      memProc.running = true
      diskProc.running = true
      volProc.running = true
    }
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      windowProc.running = true
      layoutProc.running = true
    }
  }

  Timer {
    interval: 200
    running: true
    repeat: true
    onTriggered: {
      windowProc.running = true
      layoutProc.running = true
    }
  }

  // ===== UI =====
  Rectangle {
    anchors.fill: parent
    color: Theme.colBg

    RowLayout {
      anchors.fill: parent
      spacing: 0

      Item { width: 8 }

      Rectangle {
        Layout.preferredWidth: 24
        Layout.preferredHeight: 24
        color: "transparent"
      }

      Item { width: 8 }

      Repeater {
        model: 9

        Rectangle {
          Layout.preferredWidth: 20
          Layout.preferredHeight: parent.height
          color: "transparent"

          property var workspace: Hyprland.workspaces.values.find(ws => ws.id === index + 1) ?? null
          property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)
          property bool hasWindows: workspace !== null

          Text {
            text: index + 1
            color: parent.isActive ? Theme.colCyan : (parent.hasWindows ? Theme.colCyan : Theme.colMuted)
            font.pixelSize: topBar.fontSize
            font.family: topBar.fontFamily
            font.bold: true
            anchors.centerIn: parent
          }

          Rectangle {
            width: 20
            height: 3
            color: parent.isActive ? Theme.colPurple : Theme.colBg
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
          }

          MouseArea {
            anchors.fill: parent
            onClicked: Hyprland.dispatch("workspace " + (index + 1))
          }
        }
      }

      Rectangle {
        Layout.preferredWidth: 1
        Layout.preferredHeight: 16
        Layout.alignment: Qt.AlignVCenter
        Layout.leftMargin: 8
        Layout.rightMargin: 8
        color: Theme.colMuted
      }

      Text {
        text: topBar.currentLayout
        color: Theme.colFg
        font.pixelSize: topBar.fontSize
        font.family: topBar.fontFamily
        font.bold: true
        Layout.leftMargin: 5
        Layout.rightMargin: 5
      }

      Rectangle {
        Layout.preferredWidth: 1
        Layout.preferredHeight: 16
        Layout.alignment: Qt.AlignVCenter
        Layout.leftMargin: 2
        Layout.rightMargin: 8
        color: Theme.colMuted
      }

      Text {
        text: topBar.activeWindow
        color: Theme.colPurple
        font.pixelSize: topBar.fontSize
        font.family: topBar.fontFamily
        font.bold: true
        Layout.fillWidth: true
        Layout.leftMargin: 8
        elide: Text.ElideRight
        maximumLineCount: 1
      }

      Text {
        text: topBar.kernelVersion
        color: Theme.colRed
        font.pixelSize: topBar.fontSize
        font.family: topBar.fontFamily
        font.bold: true
        Layout.rightMargin: 8
      }

      Rectangle {
        Layout.preferredWidth: 1
        Layout.preferredHeight: 16
        Layout.alignment: Qt.AlignVCenter
        Layout.leftMargin: 0
        Layout.rightMargin: 8
        color: Theme.colMuted
      }

      Text {
        text: "CPU: " + topBar.cpuUsage + "%"
        color: Theme.colYellow
        font.pixelSize: topBar.fontSize
        font.family: topBar.fontFamily
        font.bold: true
        Layout.rightMargin: 8
      }

      Rectangle {
        Layout.preferredWidth: 1
        Layout.preferredHeight: 16
        Layout.alignment: Qt.AlignVCenter
        Layout.leftMargin: 0
        Layout.rightMargin: 8
        color: Theme.colMuted
      }

      Text {
        text: "Mem: " + topBar.memUsage + "%"
        color: Theme.colCyan
        font.pixelSize: topBar.fontSize
        font.family: topBar.fontFamily
        font.bold: true
        Layout.rightMargin: 8
      }

      Rectangle {
        Layout.preferredWidth: 1
        Layout.preferredHeight: 16
        Layout.alignment: Qt.AlignVCenter
        Layout.leftMargin: 0
        Layout.rightMargin: 8
        color: Theme.colMuted
      }

      Text {
        text: "Disk: " + topBar.diskUsage + "%"
        color: Theme.colBlue
        font.pixelSize: topBar.fontSize
        font.family: topBar.fontFamily
        font.bold: true
        Layout.rightMargin: 8
      }

      Rectangle {
        Layout.preferredWidth: 1
        Layout.preferredHeight: 16
        Layout.alignment: Qt.AlignVCenter
        Layout.leftMargin: 0
        Layout.rightMargin: 8
        color: Theme.colMuted
      }

      Text {
        text: "Vol: " + topBar.volumeLevel + "%"
        color: Theme.colPurple
        font.pixelSize: topBar.fontSize
        font.family: topBar.fontFamily
        font.bold: true
        Layout.rightMargin: 8
      }

      Rectangle {
        Layout.preferredWidth: 1
        Layout.preferredHeight: 16
        Layout.alignment: Qt.AlignVCenter
        Layout.leftMargin: 0
        Layout.rightMargin: 8
        color: Theme.colMuted
      }

      Text {
        id: clockText
        text: Qt.formatDateTime(new Date(), "ddd, MMM dd - HH:mm")
        color: Theme.colCyan
        font.pixelSize: topBar.fontSize
        font.family: topBar.fontFamily
        font.bold: true
        Layout.rightMargin: 8

        Timer {
          interval: 1000
          running: true
          repeat: true
          onTriggered: clockText.text = Qt.formatDateTime(new Date(), "ddd, MMM dd - HH:mm")
        }
      }

      Item { width: 8 }
    }
  }
}
