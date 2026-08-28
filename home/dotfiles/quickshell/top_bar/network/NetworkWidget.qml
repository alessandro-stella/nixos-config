import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../"

Item {
  id: root
  
  required property PanelWindow parentWindow

  Layout.preferredWidth: iconContainer.width
  Layout.fillHeight: true

  property string connectionType: "disconnected" // "wifi", "ethernet", "disconnected", "wifi_off"
  property string ssidName: ""
  property string ipAddress: "N/A"
  property real wifiStrength: 0
  readonly property bool isWifi: connectionType === "wifi"

  Timer {
    interval: 3000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      checkNetwork.running = true
      getIp.running = true
    }
  }

  Process {
    id: checkNetwork
    command: ["sh", "-c", "nmcli -t -f TYPE,STATE,CONNECTION device | grep -E '(ethernet|wifi):connected'"]
    stdout: SplitParser {
      onRead: data => {
        if (!data || data.trim() === "") {
          root.connectionType = "disconnected"
          root.ssidName = ""
          root.wifiStrength = 0
          return
        }

        let cleaned = data.trim()

        let lines = cleaned.split("\n")
        let found = false

        for (let line of lines) {
          let parts = line.split(":")
          
          if (parts.length >= 2) {
            let type = parts[0].trim()
            let state = parts[1].trim()
            
            if (type === "ethernet" && state === "connected") {
              root.connectionType = "ethernet"
              root.ssidName = "LAN"
              root.wifiStrength = 0
              found = true
              break
            } else if (type === "wifi" && state === "connected") {
              root.connectionType = "wifi"

              if (parts.length >= 3) {
                root.ssidName = parts[2].trim()
              }
              checkWifiStrength.running = true
              found = true
              break
            }
          }
        }

        if (!found) {
          root.connectionType = "disconnected"
          root.ssidName = ""
          root.wifiStrength = 0
        }
      }
    }
  }

  Process {
    id: checkWifiStrength
    command: ["sh", "-c", "nmcli -t -f IN-USE,SIGNAL dev wifi | grep '^\\*' | cut -d: -f2"]
    stdout: SplitParser {
      onRead: data => {
        if (data) {
          root.wifiStrength = parseInt(data.trim()) || 0
        }
      }
    }
  }

  Process {
    id: getIp
    command: ["sh", "-c", "hostname -I | awk '{print $1}'"]
    stdout: SplitParser {
      onRead: data => {
        if (data && data.trim() !== "") {
          root.ipAddress = data.trim()
        } else {
          root.ipAddress = "Disconnected"
        }
      }
    }
  }

  function getWifiIcon(): string {
    if (!isWifi) return "󰤮"
    let strength = Math.max(0, Math.min(100, wifiStrength))
    if (strength === 0) return "󰤯"
    if (strength <= 25) return "󰤟"
    if (strength <= 50) return "󰤢"
    if (strength <= 75) return "󰤥"
    return "󰤨"
  }

  // Main container
  Item {
    id: iconContainer
    anchors.centerIn: parent
    width: referenceIcon.implicitWidth > 0 ? referenceIcon.implicitWidth : 18
    height: parent.height

    // Reference icon
    Text {
      id: referenceIcon
      text: "󰤨"
      anchors.centerIn: parent
      font.pixelSize: Theme.barFontSize
      font.family: Theme.fontFamily
      visible: false
    }

    // Real icon
    Text {
      id: iconText
      text: {
        if (root.connectionType === "ethernet") return "󰌗"
        if (root.connectionType === "wifi") return getWifiIcon()
        return "󰤮"
      }
      font.pixelSize: Theme.barFontSize
      font.family: Theme.fontFamily
      color: Theme.barColor
      anchors.centerIn: parent
    }
  }

  // Small popup
  PopupWindow {
    id: hoverPopup
    
    anchor.window: root.parentWindow
    anchor.item: root
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom

    // visible: {
    //   let isVisible = !networkPopup.isOpen && (mouseArea.containsMouse || tooltipRect.opacity > 0)
    //   return isVisible
    // }

    visible: true

    color: "transparent"  

    implicitWidth: tooltipRect.implicitWidth
    implicitHeight: tooltipRect.implicitHeight + Math.round(Theme.outerSpacing / 2)

    Rectangle {
      id: tooltipRect
      color: Theme.widgetDarkBackground
      border.color: Theme.accent1
      border.width: Theme.borderWidth
      radius: 6
      implicitWidth: networkTooltipText.implicitWidth + 24
      implicitHeight: 36
      
      anchors.bottom: parent.bottom
      anchors.horizontalCenter: parent.horizontalCenter

      opacity: (!networkPopup.isOpen && mouseArea.containsMouse) ? 1 : 0
      scale: (!networkPopup.isOpen && mouseArea.containsMouse) ? 1 : 0.94

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
        id: networkTooltipText
        anchors.centerIn: parent
        text: {
          if (root.connectionType === "disconnected" || root.connectionType === "wifi_off") {
            return "Disconnected"
          }
          let name = root.connectionType === "ethernet" ? "LAN" : root.ssidName
          return name + " (" + root.ipAddress + ")"
        }
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.barColor
      }
    }
  }

  NetworkPopup {
    id: networkPopup
    parentWindow: root.parentWindow
    targetItem: root
    connectionType: root.connectionType
    ssidName: root.ssidName
    ipAddress: root.ipAddress
    wifiStrength: root.wifiStrength
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      networkPopup.toggle()
    }
  }
}
