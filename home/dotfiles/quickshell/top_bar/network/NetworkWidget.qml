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

  property string connectionType: "disconnected" // "wifi", "ethernet", "disconnected"
  property string ssidName: ""

  Timer {
    interval: 3000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: checkNetwork.running = true
  }

  Process {
    id: checkNetwork
    command: ["sh", "-c", "nmcli -t -f TYPE,STATE,CONNECTION device | grep '^ethernet:connected\\|^wifi:connected'"]
    stdout: SplitParser {
      onRead: data => {
        if (!data || data.trim() === "") {
          root.connectionType = "disconnected"
          root.ssidName = ""
          return
        }

        let lines = data.trim().split("\n")
        for (let line of lines) {
          if (line.startsWith("ethernet:connected")) {
            root.connectionType = "ethernet"
            root.ssidName = "LAN"
            break
          } else if (line.startsWith("wifi:connected")) {
            root.connectionType = "wifi"
            let parts = line.split(":")
            if (parts.length >= 3) {
              root.ssidName = parts[2]
            }
            break
          }
        }
      }
    }
  }

  RowLayout {
    id: contentRow
    anchors.centerIn: parent
    spacing: 4

    Text {
      // Icona dinamica in base al tipo di connessione
      text: {
        if (root.connectionType === "ethernet") return "󰈀"
        if (root.connectionType === "wifi") return "󰖩"
        return "󰖪"
      }
      font.pixelSize: Theme.barFontSize
      font.family: Theme.fontFamily
      color: Theme.barColor
    }

    Text {
      text: root.connectionType === "wifi" ? root.ssidName : (root.connectionType === "ethernet" ? "LAN" : "Off")
      font.pixelSize: Theme.fontSizeSmall
      font.family: Theme.fontFamily
      color: Theme.barColor
      visible: root.connectionType !== "disconnected"
    }
  }

  NetworkPopup {
    id: networkPopup
    parentWindow: root.parentWindow
    targetItem: root
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: networkPopup.toggle()
  }
}
