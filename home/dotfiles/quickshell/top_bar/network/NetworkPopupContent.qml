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

  ListModel {
    id: wifiModel
  }

  Component.onCompleted: {
    checkWifiStatus.running = true
    refreshNetworks()
  }

  // Controlla se il Wi-Fi è acceso o spento
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

  // Forza una scansione pulita e poi legge le reti e quella attiva
  Process {
    id: scanAndReadProcess
    command: ["sh", "-c", "nmcli device wifi rescan 2>/dev/null; sleep 1; nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi"]
    stdout: SplitParser {
      onRead: data => {
        if (!data || data.trim() === "") return
        
        wifiModel.clear()
        currentConnectedSsid = ""
        currentConnectedSignal = ""

        let lines = data.trim().split("\n")
        let seenSsids = {}

        for (let line of lines) {
          let parts = line.split(":")
          if (parts.length >= 4) {
            let inUse = parts[0] === "*"
            let ssid = parts[1]
            let signal = parts[2] + "%"
            let security = parts[3]

            if (ssid !== "" && !seenSsids[ssid]) {
              seenSsids[ssid] = true

              if (inUse) {
                currentConnectedSsid = ssid
                currentConnectedSignal = signal
              } else {
                wifiModel.append({
                  "ssid": ssid,
                  "signal": signal,
                  "security": security
                })
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
    scanAndReadProcess.running = true
  }

  ColumnLayout {
    id: mainLayout
    anchors.fill: parent
    spacing: 16

    // Header: "AIRCTL" o titolo + Toggle Wi-Fi + Rotellina impostazioni avanzate
    RowLayout {
      Layout.fillWidth: true

      Text {
        text: "Network Settings"
        font.bold: true
        font.pixelSize: Theme.fontSize
        color: Theme.barColor
        Layout.fillWidth: true
      }

      // Rotellina per aprire l'editor avanzato di NetworkManager
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

    // Sezione interruttore Wi-Fi principale (stile switch della foto)
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

        // Custom Switch Toggle
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
              refreshNetworks()
            }
          }
        }
      }
    }

    // Box della Rete Attuale (se connesso)
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 6
      visible: contentRoot.currentConnectedSsid !== ""

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

          Text {
            text: "󰁞" // Freccia o indicatore
            font.pixelSize: 14
            color: Theme.barDarkColor
          }
        }
      }
    }

    // Sezione Reti Disponibili con pulsante di aggiornamento (freccia circolare)
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 6

      RowLayout {
        Layout.fillWidth: true

        Text {
          text: "Networks"
          font.pixelSize: Theme.fontSizeSmall
          font.bold: true
          color: Theme.barDarkColor
          Layout.fillWidth: true
        }

        // Tasto di refresh manuale (la rotellina/freccia circolare della foto)
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

      // Lista delle reti
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
              // Ricarica la lista dopo qualche secondo per aggiornare lo stato
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
