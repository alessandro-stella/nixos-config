import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../"

Item {
  id: contentRoot

  implicitHeight: mainLayout.implicitHeight
  implicitWidth: 320

  ListModel {
    id: wifiModel
  }

  function refreshWifi() {
    scanProcess.running = true
  }

  Component.onCompleted: {
    refreshWifi()
  }

  // Scansiona le reti Wi-Fi vicine
  Process {
    id: scanProcess
    command: ["sh", "-c", "nmcli -t -f IN-USE,SSID,BARS,SECURITY dev wifi"]
    stdout: SplitParser {
      onRead: data => {
        if (!data || data.trim() === "") return
        
        wifiModel.clear()
        let lines = data.trim().split("\n")
        for (let line of lines) {
          let parts = line.split(":")
          if (parts.length >= 4) {
            let inUse = parts[0] === "*"
            let ssid = parts[1]
            let bars = parts[2]
            let security = parts[3]

            if (ssid !== "") {
              wifiModel.append({
                "ssid": ssid,
                "inUse": inUse,
                "bars": bars,
                "security": security
              })
            }
          }
        }
      }
    }
  }

  // Processo per connettersi a una rete Wi-Fi
  Process {
    id: connectProcess
    command: ["sh", "-c", ""]
  }

  // Processo per aprire l'editor avanzato di NetworkManager (es. nm-connection-editor)
  Process {
    id: openEditorProcess
    command: ["nm-connection-editor"]
  }

  ColumnLayout {
    id: mainLayout
    anchors.fill: parent
    spacing: 12

    // Header con Titolo e Rotellina per modifiche avanzate
    RowLayout {
      Layout.fillWidth: true

      Text {
        text: "Reti Wi-Fi"
        font.bold: true
        font.pixelSize: Theme.fontSize
        color: Theme.barColor
        Layout.fillWidth: true
      }

      // Pulsante Rotellina / Impostazioni Avanzate
      Rectangle {
        width: 28
        height: 28
        radius: 6
        color: settingsMouse.containsMouse ? Theme.widgetLightBackground : "transparent"

        Text {
          anchors.centerIn: parent
          text: "" // Glyph della rotellina (FontAwesome o simile)
          font.pixelSize: Theme.fontSizeSmall
          color: Theme.barColor
        }

        MouseArea {
          id: settingsMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            openEditorProcess.running = true
          }
        }
      }
    }

    // Lista delle reti Wi-Fi
    ListView {
      id: wifiListView
      Layout.fillWidth: true
      Layout.preferredHeight: Math.min(contentHeight, 220)
      model: wifiModel
      clip: true
      spacing: 6

      delegate: Rectangle {
        required property string ssid
        required property bool inUse
        required property string bars
        required property string security

        width: wifiListView.width
        height: 36
        radius: 6
        color: inUse ? Theme.widgetLightBackground : (delegateMouse.containsMouse ? Theme.widgetLightBackground : "transparent")

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 8
          anchors.rightMargin: 8
          spacing: 10

          Text {
            text: ssid
            font.pixelSize: Theme.fontSizeSmall
            font.bold: inUse
            color: Theme.barColor
            Layout.fillWidth: true
            elide: Text.ElideRight
          }

          Text {
            text: security !== "" ? "" : ""
            font.pixelSize: 10
            color: Theme.barDarkColor
          }

          Text {
            text: inUse ? "Connesso" : ""
            font.pixelSize: 10
            font.bold: true
            color: Theme.colGreen
          }
        }

        MouseArea {
          id: delegateMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            // Esegue la connessione tramite nmcli
            connectProcess.command = ["sh", "-c", "nmcli dev wifi connect '" + ssid + "'"]
            connectProcess.running = true
          }
        }
      }
    }
  }
}
