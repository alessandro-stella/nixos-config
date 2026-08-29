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
  property bool isConnecting: false
  readonly property bool isWifi: connectionType === "wifi"

  // Lettura iniziale
  Component.onCompleted: {
    checkNetwork.running = true
  }

  // Processo Sentinella silenzioso
  Process {
    id: networkMonitor
    command: ["nmcli", "monitor"]
    running: true

    stdout: SplitParser {
      onRead: data => {
        if (!data) return
        let line = data.trim().toLowerCase()
        
        if (line.includes("connected") || 
            line.includes("disconnected") || 
            line.includes("unavailable") || 
            line.includes("primary connection") ||
            line.includes("connection profile changed") ||
            line.includes("connecting")) {
          
          checkNetwork.running = true
        }
      }
    }
  }

  Process {
    id: checkNetwork
    command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "device"]
    property string accumulatedOutput: ""

    onRunningChanged: {
      if (running) {
        accumulatedOutput = ""
      } else {
        if (accumulatedOutput.trim() === "") {
          root.connectionType = "disconnected"
          root.ssidName = ""
          root.wifiStrength = 0
          root.isConnecting = false
          return
        }

        let lines = accumulatedOutput.trim().split("\n")
        let isConnected = false
        let isWifiUnavailable = false

        for (let line of lines) {
          let parts = line.split(":")
          
          if (parts.length >= 2) {
            let type = parts[0].trim()
            let state = parts[1].trim()
            
            // Gestione della LAN (Ethernet)
            if (type === "ethernet" && state === "connected") {
              root.connectionType = "ethernet"
              root.ssidName = "LAN"
              root.wifiStrength = 0
              root.isConnecting = false
              isConnected = true
              break
            } else if (type === "wifi") {
              if (state === "connected") {
                root.connectionType = "wifi"
                if (parts.length >= 3) {
                  root.ssidName = parts[2].trim()
                }
                root.isConnecting = false
                checkWifiStrength.running = true
                isConnected = true
                break
              } else if (state.startsWith("connecting")) {
                root.connectionType = "wifi"
                if (parts.length >= 3) {
                  root.ssidName = parts[2].trim()
                }
                root.isConnecting = true
                isConnected = true
                break
              } else if (state === "unavailable") {
                isWifiUnavailable = true
              }
            }
          }
        }

        // Valutazione finale (Staffetta con getIp)
        if (!isConnected) {
          root.connectionType = isWifiUnavailable ? "wifi_off" : "disconnected"
          root.ssidName = ""
          root.wifiStrength = 0
          root.ipAddress = "Disconnected"
          root.isConnecting = false
        } else if (!root.isConnecting) {
          getIp.running = true
        }
      }
    }

    stdout: SplitParser {
      onRead: data => {
        if (data) {
          checkNetwork.accumulatedOutput += data + "\n"
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
        if (root.connectionType === "disconnected" || root.connectionType === "wifi_off") {
          root.ipAddress = "Disconnected"
          return
        }
        
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

  Item {
    id: iconContainer
    anchors.centerIn: parent
    width: referenceIcon.implicitWidth > 0 ? referenceIcon.implicitWidth : 18
    height: parent.height

    Text {
      id: referenceIcon
      text: "󰤨"
      anchors.centerIn: parent
      font.pixelSize: Theme.barFontSize
      font.family: Theme.fontFamily
      visible: false
    }

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

  PopupWindow {
    id: hoverPopup
    
    anchor.window: root.parentWindow
    anchor.item: root
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom

    visible: !networkPopup.isOpen && (mouseArea.containsMouse || tooltipRect.opacity > 0)
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
        NumberAnimation { duration: Theme.fastAnimation; easing.type: Easing.OutCubic }
      }
      Behavior on scale {
        NumberAnimation { duration: Theme.fastAnimation; easing.type: Easing.OutCubic }
      }

      Text {
        id: networkTooltipText
        anchors.centerIn: parent
        text: {
          if (root.connectionType === "disconnected" || root.connectionType === "wifi_off") {
            return "Disconnected"
          }
          if (root.isConnecting) {
            return "Connecting to " + root.ssidName + "..."
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
    isConnecting: root.isConnecting // <-- Non dimentichiamolo!
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
