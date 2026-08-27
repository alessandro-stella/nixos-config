import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../"

Item {
  id: contentRoot

  implicitHeight: mainLayout.implicitHeight
  implicitWidth: 350

  property bool wifiEnabled: true
  property string currentConnectedSsid: ""
  property string currentConnectedSignal: ""
  property bool isOpen: false // Gestito dal loader del popup se necessario o tracciato

  ListModel {
    id: wifiModel
  }

  Component.onCompleted: {
    checkWifiStatus.running = true
    refreshNetworks()
  }

  // Timer di polling periodico (ogni 5 secondi aggiorna la lista reti se aperto)
  Timer {
    interval: 5000
    running: true
    repeat: true
    onTriggered: {
      if (contentRoot.wifiEnabled) {
        refreshNetworks()
      }
    }
  }

  Process {
    id: checkWifiStatus
    command: ["sh", "-c", "nmcli radio wifi"]
    stdout: SplitParser {
      onRead: data => {
        if (data) {
          contentRoot.wifiEnabled = data.trim() === "enabled"
        }
      }
    }
  }

  // Processo di scansione e lettura con output di debug in console
  Process {
    id: scanAndReadProcess
    command: ["sh", "-c", "nmcli device wifi rescan 2>/dev/null; sleep 0.5; nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi"]
    stdout: SplitParser {
      onRead: data => {
        if (!data || data.trim() === "") return
        
        console.log("[NetworkWidget] Output grezzo nmcli:\n" + data.trim())

        wifiModel.clear()
        currentConnectedSsid = ""
        currentConnectedSignal = ""

        let lines = data.trim().split("\n")
        let seenSsids = {}

        for (let line of lines) {
          // nmcli -t usa ':' come separatore, ma a volte gli SSID possono contenere ':' o caratteri speciali. 
          // Dividiamo prendendo il primo come in-use, gli ultimi due come signal e security, e il mezzo come ssid.
          let firstColon = line.indexOf(":")
          let lastColon = line.lastIndexOf(":")
          let secondLastColon = line.lastIndexOf(":", lastColon - 1)

          if (firstColon !== -1 && lastColon !== -1 && secondLastColon !== -1 && firstColon < secondLastColon) {
            let inUse = line.substring(0, firstColon) === "*"
            let ssid = line.substring(firstColon + 1, secondLastColon)
            let signal = line.substring(secondLastColon + 1, lastColon) + "%"
            let security = line.substring(lastColon + 1)

            // Pulisce eventuali apici superflui dall'SSID
            ssid = ssid.replace(/^["']|["']$/g, "").trim()

            if (ssid !== "" && !seenSsids[ssid]) {
              seenSsids[ssid] = true

              if (inUse) {
                currentConnectedSsid = ssid
                currentConnectedSignal = signal
                console.log("[NetworkWidget] Trovata rete CONNESSA: " + ssid)
              } else {
                wifiModel.append({
                  "ssid": ssid,
                  "signal": signal,
                  "security": security
                })
                console.log("[NetworkWidget] Aggiunta rete disponibile: " + ssid + " (" + signal + ")")
              }
            }
          }
        }
      }
    }
  }

  Process {
    id: toggleWifiProcess
    command: ["sh", "-c", ""]
  }

  Process {
    id: connectProcess
    command: ["sh", "-c", ""]
  }

  Process {
    id: openEditorProcess
    command: ["nm-connection-editor"]
  }

  function refreshNetworks() {
    checkWifiStatus.running = true
    scanAndReadProcess.running = true
  }

  ColumnLayout {
    id: mainLayout
    anchors.fill: parent
    spacing: 16

    // Header con Titolo e Rotellina Impostazioni
    RowLayout {
      Layout.fillWidth: true

      Text {
        text: "Network Settings"
        font.bold: true
        font.pixelSize: Theme.fontSize
        color: Theme.barColor
        Layout.fillWidth: true
      }

      Rectangle {
        width: 28
        height: 28
        radius: 6
        color: settingsMouse.containsMouse ? Theme.widgetLightBackground : "transparent"

        Text {
          anchors.centerIn: parent
          text: ""
          font.pixelSize: Theme.fontSizeSmall
          color: Theme.barColor
        }

        MouseArea {
          id: settingsMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: openEditorProcess.running = true
        }
      }
    }

    // Toggle Wi-Fi Principale
    Rectangle {
      Layout.fillWidth: true
      height: 48
      radius: 8
      color: Theme.widgetLightBackground

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12

        Text {
          text: "Use Wi-Fi"
          font.bold: true
          font.pixelSize: Theme.fontSizeSmall
          color: Theme.barColor
          Layout.fillWidth: true
        }

        Rectangle {
          width: 40
          height: 22
          radius: 11
          color: contentRoot.wifiEnabled ? Theme.colGreen : Theme.barDarkColor

          Rectangle {
            width: 18
            height: 18
            radius: 9
            y: 2
            x: contentRoot.wifiEnabled ? 20 : 2
            color: "white"

            Behavior on x {
              NumberAnimation { duration: 150 }
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              let newState = contentRoot.wifiEnabled ? "off" : "on"
              toggleWifiProcess.command = ["sh", "-c", "nmcli radio wifi " + newState]
              toggleWifiProcess.running = true
              contentRoot.wifiEnabled = !contentRoot.wifiEnabled
              if (!contentRoot.wifiEnabled) {
                wifiModel.clear()
                currentConnectedSsid = ""
              } else {
                refreshNetworks()
              }
            }
          }
        }
      }
    }

    // Box Rete Attuale
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 6
      visible: contentRoot.wifiEnabled && contentRoot.currentConnectedSsid !== ""

      Text {
        text: "Connected"
        font.pixelSize: Theme.fontSizeSmall
        font.bold: true
        color: Theme.barDarkColor
      }

      Rectangle {
        Layout.fillWidth: true
        height: 50
        radius: 8
        color: Theme.widgetLightBackground

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 12
          anchors.rightMargin: 12
          spacing: 10

          Text {
            text: "󰖩"
            font.pixelSize: 18
            color: Theme.colGreen
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
              text: contentRoot.currentConnectedSsid
              font.bold: true
              font.pixelSize: Theme.fontSizeSmall
              color: Theme.barColor
              elide: Text.ElideRight
            }

            Text {
              text: "Connected"
              font.pixelSize: 10
              color: Theme.colGreen
            }
          }

          Text {
            text: contentRoot.currentConnectedSignal
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.barDarkColor
          }
        }
      }
    }

    // Sezione Reti Disponibili
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 6
      visible: contentRoot.wifiEnabled

      RowLayout {
        Layout.fillWidth: true

        Text {
          text: "Networks"
          font.pixelSize: Theme.fontSizeSmall
          font.bold: true
          color: Theme.barDarkColor
          Layout.fillWidth: true
        }

        Rectangle {
          width: 22
          height: 22
          radius: 4
          color: refreshMouse.containsMouse ? Theme.widgetLightBackground : "transparent"

          Text {
            anchors.centerIn: parent
            text: "󰑐"
            font.pixelSize: 12
            color: Theme.barColor
          }

          MouseArea {
            id: refreshMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: refreshNetworks()
          }
        }
      }

      ListView {
        id: wifiListView
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 180)
        model: wifiModel
        clip: true
        spacing: 6

        delegate: Rectangle {
          required property string ssid
          required property string signal
          required property string security

          width: wifiListView.width
          height: 44
          radius: 8
          color: delegateMouse.containsMouse ? Theme.widgetLightBackground : "transparent"

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 10

            Text {
              text: "󰖩"
              font.pixelSize: 16
              color: Theme.barColor
            }

            Text {
              text: ssid
              font.pixelSize: Theme.fontSizeSmall
              font.bold: true
              color: Theme.barColor
              Layout.fillWidth: true
              elide: Text.ElideRight
            }

            Text {
              text: signal
              font.pixelSize: Theme.fontSizeSmall
              color: Theme.barDarkColor
            }

            Text {
              text: security !== "" ? "" : ""
              font.pixelSize: 12
              color: Theme.barDarkColor
            }
          }

          MouseArea {
            id: delegateMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              connectProcess.command = ["sh", "-c", "nmcli dev wifi connect '" + ssid + "'"]
              connectProcess.running = true
              refreshTimer.restart()
            }
          }
        }
      }
    }
  }

  Timer {
    id: refreshTimer
    interval: 3000
    onTriggered: refreshNetworks()
  }
}
