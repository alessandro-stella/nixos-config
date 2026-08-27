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

  property string connectionType: "disconnected" // "wifi", "ethernet", "disconnected", "wifi_off"
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
    command: ["sh", "-c", "if [ \"$(nmcli radio wifi)\" = \"disabled\" ]; then echo \"wifi:disabled\"; else nmcli -t -f TYPE,STATE,CONNECTION device | grep '^ethernet:connected\\|^wifi:connected'; fi"]
    stdout: SplitParser {
      onRead: data => {
        if (!data || data.trim() === "") {
          root.connectionType = "disconnected"
          root.ssidName = ""
          return
        }

        let cleaned = data.trim()
        if (cleaned === "wifi:disabled") {
          root.connectionType = "wifi_off"
          root.ssidName = "Off"
          return
        }

        let lines = cleaned.split("\n")
        let found = false
        for (let line of lines) {
          if (line.startsWith("ethernet:connected")) {
            root.connectionType = "ethernet"
            root.ssidName = "LAN"
            found = true
            break
          } else if (line.startsWith("wifi:connected")) {
            root.connectionType = "wifi"
            let parts = line.split(":")
            if (parts.length >= 3) {
              root.ssidName = parts[2]
            }
            found = true
            break
          }
        }
        if (!found) {
          root.connectionType = "disconnected"
          root.ssidName = ""
        }
      }
    }
  }

  RowLayout {
    id: contentRow
    anchors.centerIn: parent
    spacing: 4

    Text {
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
      visible: root.connectionType !== "disconnected" && root.connectionType !== "wifi_off"
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
