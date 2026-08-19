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

  // ===== CONFIGURAZIONE FONT =====
  readonly property int barFontSize: 12
  readonly property string barFontFamily: "monospace"

  // ===== PROPRIETÀ REATTIVE (Zero CPU overhead) =====
  readonly property string activeWindow: Hyprland.focusedWindow?.title ?? ""
  readonly property string currentLayout: {
    const win = Hyprland.focusedWindow
    if (!win) return "Tiled"
    if (win.floating) return "Floating"
    if (win.fullscreen) return "Fullscreen"
    return "Tiled"
  }

  // ===== PROPRIETÀ STATO SISTEMA =====
  property string kernelVersion: "Linux"
  property int cpuUsage: 0
  property int memUsage: 0
  property int diskUsage: 0
  property int volumeLevel: 0
  property var lastCpuIdle: 0
  property var lastCpuTotal: 0
  property var _memTotal: null

  // 1. Kernel: Eseguito una sola volta all'avvio
  Process {
    command: ["uname", "-r"]
    running: true
    stdout: SplitParser {
      onRead: data => {
        if (data) topBar.kernelVersion = data.trim()
      }
    }
  }

  // 2. Metriche aggregate: CPU, RAM e Disco insieme
  Process {
    id: sysStatsProc
    command: [
      "sh", "-c",
      "head -n1 /proc/stat; grep -E 'MemTotal|MemAvailable' /proc/meminfo; df -h / | awk 'NR==2 {print $5}'"
    ]
    stdout: SplitParser {
      onRead: data => {
        if (!data || data.trim() === "") return
        const line = data.trim()

        // Calcolo CPU
        if (line.startsWith("cpu ")) {
          const parts = line.split(/\s+/)
          const user = parseInt(parts[1]) || 0
          const nice = parseInt(parts[2]) || 0
          const system = parseInt(parts[3]) || 0
          const idle = parseInt(parts[4]) || 0
          const iowait = parseInt(parts[5]) || 0
          const irq = parseInt(parts[6]) || 0
          const softirq = parseInt(parts[7]) || 0

          const total = user + nice + system + idle + iowait + irq + softirq
          const idleTime = idle + iowait

          if (topBar.lastCpuTotal > 0) {
            const totalDiff = total - topBar.lastCpuTotal
            const idleDiff = idleTime - topBar.lastCpuIdle
            if (totalDiff > 0) {
              topBar.cpuUsage = Math.max(0, Math.min(100, Math.round(100 * (totalDiff - idleDiff) / totalDiff)))
            }
          }
          topBar.lastCpuTotal = total
          topBar.lastCpuIdle = idleTime
        }
        // Calcolo Memoria da /proc/meminfo
        else if (line.startsWith("MemTotal:")) {
          topBar._memTotal = parseInt(line.replace(/[^0-9]/g, "")) || 1
        }
        else if (line.startsWith("MemAvailable:")) {
          const avail = parseInt(line.replace(/[^0-9]/g, "")) || 0
          if (topBar._memTotal) {
            topBar.memUsage = Math.round(100 * (topBar._memTotal - avail) / topBar._memTotal)
          }
        }
        // Percentuale Disco (es. 45%)
        else if (line.endsWith("%")) {
          topBar.diskUsage = parseInt(line.replace("%", "")) || 0
        }
      }
    }
    Component.onCompleted: running = true
  }

  // 3. Volume
  Process {
    id: volProc
    command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
    stdout: SplitParser {
      onRead: data => {
        if (!data) return
        const match = data.match(/Volume:\s*([\d.]+)/)
        if (match) {
          topBar.volumeLevel = Math.round(parseFloat(match[1]) * 100)
        }
      }
    }
    Component.onCompleted: running = true
  }

  // Timer per aggiornare le statistiche ogni 2 secondi
  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: {
      sysStatsProc.running = true
      volProc.running = true
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

      // Workspace Selector (Lookup diretto O(1))
      Repeater {
        model: 9

        Rectangle {
          Layout.preferredWidth: 20
          Layout.preferredHeight: parent.height
          color: "transparent"

          readonly property int wsId: index + 1
          readonly property var workspace: Hyprland.workspaces.get(wsId) ?? null
          readonly property bool isActive: Hyprland.focusedWorkspace?.id === wsId
          readonly property bool hasWindows: workspace !== null

          Text {
            text: parent.wsId
            color: parent.isActive ? Theme.colCyan : (parent.hasWindows ? Theme.colCyan : Theme.colMuted)
            font.pixelSize: topBar.barFontSize
            font.family: topBar.barFontFamily
            font.bold: true
            anchors.centerIn: parent
          }

          Rectangle {
            width: 20
            height: 3
            color: parent.isActive ? Theme.colPurple : "transparent"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Hyprland.dispatch("workspace " + parent.wsId)
          }
        }
      }

      // Separatore
      Rectangle {
        Layout.preferredWidth: 1
        Layout.preferredHeight: 16
        Layout.alignment: Qt.AlignVCenter
        Layout.leftMargin: 8
        Layout.rightMargin: 8
        color: Theme.colMuted
      }

      // Layout Finestra
      Text {
        text: topBar.currentLayout
        color: Theme.colFg
        font.pixelSize: topBar.barFontSize
        font.family: topBar.barFontFamily
        font.bold: true
        Layout.leftMargin: 5
        Layout.rightMargin: 5
      }

      // Separatore
      Rectangle {
        Layout.preferredWidth: 1
        Layout.preferredHeight: 16
        Layout.alignment: Qt.AlignVCenter
        Layout.leftMargin: 2
        Layout.rightMargin: 8
        color: Theme.colMuted
      }

      // Titolo Finestra Attiva
      Text {
        text: topBar.activeWindow
        color: Theme.colPurple
        font.pixelSize: topBar.barFontSize
        font.family: topBar.barFontFamily
        font.bold: true
        Layout.fillWidth: true
        Layout.leftMargin: 8
        elide: Text.ElideRight
        maximumLineCount: 1
      }

      // Kernel
      Text {
        text: topBar.kernelVersion
        color: Theme.colRed
        font.pixelSize: topBar.barFontSize
        font.family: topBar.barFontFamily
        font.bold: true
        Layout.rightMargin: 8
      }

      // Separatore
      Rectangle {
        Layout.preferredWidth: 1
        Layout.preferredHeight: 16
        Layout.alignment: Qt.AlignVCenter
        Layout.rightMargin: 8
        color: Theme.colMuted
      }

      // CPU
      Text {
        text: "CPU: " + topBar.cpuUsage + "%"
        color: Theme.colYellow
        font.pixelSize: topBar.barFontSize
        font.family: topBar.barFontFamily
        font.bold: true
        Layout.rightMargin: 8
      }

      // Separatore
      Rectangle {
        Layout.preferredWidth: 1
        Layout.preferredHeight: 16
        Layout.alignment: Qt.AlignVCenter
        Layout.rightMargin: 8
        color: Theme.colMuted
      }

      // Memoria
      Text {
        text: "Mem: " + topBar.memUsage + "%"
        color: Theme.colCyan
        font.pixelSize: topBar.barFontSize
        font.family: topBar.barFontFamily
        font.bold: true
        Layout.rightMargin: 8
      }

      // Separatore
      Rectangle {
        Layout.preferredWidth: 1
        Layout.preferredHeight: 16
        Layout.alignment: Qt.AlignVCenter
        Layout.rightMargin: 8
        color: Theme.colMuted
      }

      // Disco
      Text {
        text: "Disk: " + topBar.diskUsage + "%"
        color: Theme.colBlue
        font.pixelSize: topBar.barFontSize
        font.family: topBar.barFontFamily
        font.bold: true
        Layout.rightMargin: 8
      }

      // Separatore
      Rectangle {
        Layout.preferredWidth: 1
        Layout.preferredHeight: 16
        Layout.alignment: Qt.AlignVCenter
        Layout.rightMargin: 8
        color: Theme.colMuted
      }

      // Volume
      Text {
        text: "Vol: " + topBar.volumeLevel + "%"
        color: Theme.colPurple
        font.pixelSize: topBar.barFontSize
        font.family: topBar.barFontFamily
        font.bold: true
        Layout.rightMargin: 8
      }

      // Separatore
      Rectangle {
        Layout.preferredWidth: 1
        Layout.preferredHeight: 16
        Layout.alignment: Qt.AlignVCenter
        Layout.rightMargin: 8
        color: Theme.colMuted
      }

      // Orologio
      Text {
        id: clockText
        text: Qt.formatDateTime(new Date(), "ddd, MMM dd - HH:mm")
        color: Theme.colCyan
        font.pixelSize: topBar.barFontSize
        font.family: topBar.barFontFamily
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
