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
  property bool isScanning: false
  property string currentConnectedSsid: ""
  property string currentConnectedSignal: ""
  
  property string selectedSsidForPassword: ""
  property bool showPasswordInput: false

  property var scanBuffer: ({})
  property string bufferedConnectedSsid: ""
  property string bufferedConnectedSignal: ""

  ListModel {
    id: wifiModel
  }

  Component.onCompleted: {
    checkWifiStatus.running = true
    refreshNetworks()
  }

  Timer {
    interval: 5000
    running: true
    repeat: true
    onTriggered: {
      if (contentRoot.wifiEnabled && !contentRoot.showPasswordInput && !contentRoot.isScanning) {
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

  Process {
    id: scanAndReadProcess
    command: ["sh", "-c", "nmcli device wifi rescan 2>/dev/null; sleep 0.5; nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi"]
    
    onRunningChanged: {
      if (running) {
        contentRoot.isScanning = true
        contentRoot.scanBuffer = {}
        contentRoot.bufferedConnectedSsid = ""
        contentRoot.bufferedConnectedSignal = ""
      } else {
        contentRoot.isScanning = false
        let foundSsids = contentRoot.scanBuffer

        contentRoot.currentConnectedSsid = contentRoot.bufferedConnectedSsid
        contentRoot.currentConnectedSignal = contentRoot.bufferedConnectedSignal

        for (let ssid in foundSsids) {
          let netInfo = foundSsids[ssid]
          let foundIndex = -1

          for (let i = 0; i < wifiModel.count; i++) {
            if (wifiModel.get(i).ssid === ssid) {
              foundIndex = i
              break
            }
          }

          if (foundIndex !== -1) {
            let currentItem = wifiModel.get(foundIndex)
            if (currentItem.signal !== netInfo.signal || currentItem.security !== netInfo.security) {
              wifiModel.setProperty(foundIndex, "signal", netInfo.signal)
              wifiModel.setProperty(foundIndex, "security", netInfo.security)
            }
          } else {
            wifiModel.append({
              "ssid": ssid,
              "signal": netInfo.signal,
              "security": netInfo.security
            })
          }
        }

        for (let i = wifiModel.count - 1; i >= 0; i--) {
          let existingSsid = wifiModel.get(i).ssid
          if (!foundSsids[existingSsid]) {
            wifiModel.remove(i)
          }
        }
      }
    }

    stdout: SplitParser {
      onRead: data => {
        if (!data || data.trim() === "") return

        let lines = data.trim().split("\n")
        let currentBuffer = contentRoot.scanBuffer

        for (let line of lines) {
          if (line.trim() === "") continue

          let firstColon = line.indexOf(":")
          let lastColon = line.lastIndexOf(":")
          let secondLastColon = line.lastIndexOf(":", lastColon - 1)

          if (firstColon !== -1 && lastColon !== -1 && secondLastColon !== -1 && firstColon < secondLastColon) {
            let inUse = line.substring(0, firstColon) === "*"
            let ssid = line.substring(firstColon + 1, secondLastColon)
            let signal = line.substring(secondLastColon + 1, lastColon) + "%"
            let security = line.substring(lastColon + 1)

            ssid = ssid.replace(/^["']|["']$/g, "").trim()

            if (ssid !== "") {
              if (inUse) {
                contentRoot.bufferedConnectedSsid = ssid
                contentRoot.bufferedConnectedSignal = signal
              } else {
                currentBuffer[ssid] = {
                  "signal": signal,
                  "security": security
                }
              }
            }
          }
        }
        contentRoot.scanBuffer = currentBuffer
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

  // Processo di supporto per verificare se una rete ha già un profilo salvato e connettersi o chiedere password
  Process {
    id: checkAndConnectProcess
    property string targetSsid: ""
    property string targetSecurity: ""
    command: ["sh", "-c", ""]
    
    onRunningChanged: {
      if (!running && targetSsid !== "") {
        // Se il comando è terminato, ricarica
        refreshTimer.restart()
      }
    }
  }

  function refreshNetworks() {
    checkWifiStatus.running = true
    if (!scanAndReadProcess.running) {
      scanAndReadProcess.running = true
    }
  }

  ColumnLayout {
    id: mainLayout
    anchors.fill: parent
    spacing: 14

    // Header
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
          onClicked: {
            openEditorProcess.command = ["nm-connection-editor"]
            openEditorProcess.running = true
          }
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
              contentRoot.showPasswordInput = false
              if (!contentRoot.wifiEnabled) {
                wifiModel.clear()
                contentRoot.currentConnectedSsid = ""
              } else {
                refreshNetworks()
              }
            }
          }
        }
      }
    }

    // Sezione Password
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 6
      visible: contentRoot.showPasswordInput

      Text {
        text: "Password Required"
        font.pixelSize: Theme.fontSizeSmall
        font.bold: true
        color: Theme.colYellow
      }

      Rectangle {
        Layout.fillWidth: true
        height: 75
        radius: 8
        color: Theme.widgetLightBackground

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: 10
          spacing: 6

          Text {
            text: contentRoot.selectedSsidForPassword
            font.pixelSize: 11
            font.bold: true
            color: Theme.barColor
            elide: Text.ElideRight
            Layout.fillWidth: true
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
              Layout.fillWidth: true
              height: 30
              radius: 6
              color: Theme.barDarkColor
              border.color: Theme.colBlue
              border.width: 1

              TextInput {
                id: passwordInput
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                verticalAlignment: TextInput.AlignVCenter
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.barColor
                echoMode: TextInput.Password

                Timer {
                  interval: 50
                  running: contentRoot.showPasswordInput
                  repeat: true
                  onTriggered: {
                    if (contentRoot.showPasswordInput && !passwordInput.activeFocus) {
                      passwordInput.forceActiveFocus()
                    }
                  }
                }

                onAccepted: {
                  connectProcess.command = ["sh", "-c", "nmcli dev wifi connect '" + contentRoot.selectedSsidForPassword + "' password '" + text + "'"]
                  connectProcess.running = true
                  contentRoot.showPasswordInput = false
                  text = ""
                  refreshTimer.restart()
                }
              }

              MouseArea {
                anchors.fill: parent
                onClicked: passwordInput.forceActiveFocus()
              }
            }

            Rectangle {
              width: 55
              height: 30
              radius: 6
              color: Theme.colGreen

              Text {
                anchors.centerIn: parent
                text: "Join"
                font.pixelSize: 11
                font.bold: true
                color: "white"
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  connectProcess.command = ["sh", "-c", "nmcli dev wifi connect '" + contentRoot.selectedSsidForPassword + "' password '" + passwordInput.text + "'"]
                  connectProcess.running = true
                  contentRoot.showPasswordInput = false
                  passwordInput.text = ""
                  refreshTimer.restart()
                }
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
      visible: contentRoot.wifiEnabled && contentRoot.currentConnectedSsid !== "" && !contentRoot.showPasswordInput

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

        RowLayout {
          spacing: 6
          visible: contentRoot.isScanning

          Text {
            text: "Ricerca..."
            font.pixelSize: 10
            color: Theme.barDarkColor
          }

          Text {
            text: "󰑐"
            font.pixelSize: 12
            color: Theme.barColor

            RotationAnimation on rotation {
              running: contentRoot.isScanning
              loops: Animation.Infinite
              from: 0
              to: 360
              duration: 1000
            }
          }
        }

        Rectangle {
          width: 22
          height: 22
          radius: 4
          visible: !contentRoot.isScanning
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

      Text {
        text: "Nessuna rete trovata"
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.barDarkColor
        visible: wifiModel.count === 0 && !contentRoot.isScanning
        Layout.topMargin: 8
        Layout.bottomMargin: 8
        Layout.alignment: Qt.AlignHCenter
      }

      ListView {
        id: wifiListView
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 150)
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

            // MouseArea dedicata esclusivamente alla connessione (collegata solo al blocco a sinistra: icona + nome)
            RowLayout {
              Layout.fillWidth: true
              spacing: 10

              MouseArea {
                id: connectArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  // Controlla se la rete è protetta e se NON esiste già un profilo salvato in NetworkManager
                  if (security !== "") {
                    checkAndConnectProcess.targetSsid = ssid
                    checkAndConnectProcess.command = ["sh", "-c", "if nmcli -t -f NAME connection show | grep -Fxeq '" + ssid + "'; then nmcli dev wifi connect '" + ssid + "'; else exit 1; fi"]
                    // Se il comando fallisce (perché non è salvata), apre l'input password
                    checkAndConnectProcess.onExited = (exitCode) => {
                      if (exitCode !== 0) {
                        contentRoot.selectedSsidForPassword = ssid
                        contentRoot.showPasswordInput = true
                      }
                    }
                    checkAndConnectProcess.running = true
                  } else {
                    connectProcess.command = ["sh", "-c", "nmcli dev wifi connect '" + ssid + "'"]
                    connectProcess.running = true
                    refreshTimer.restart()
                  }
                }
              }

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

            // Rotellina impostazioni (isolata con il suo MouseArea indipendente che usa l'UUID corretto)
            Rectangle {
              width: 24
              height: 24
              radius: 4
              color: editMouse.containsMouse ? Theme.barDarkColor : "transparent"
              visible: delegateMouse.containsMouse

              Text {
                anchors.centerIn: parent
                text: ""
                font.pixelSize: 11
                color: Theme.barColor
              }

             MouseArea {
                id: editMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => {
                  mouse.accepted = true
                  // Cerca il nome esatto della connessione o fallisce aprendo l'editor generale
                  openEditorProcess.command = ["sh", "-c", "UUID=$(nmcli -t -f NAME,UUID connection show | grep '^" + ssid + "$' | cut -d: -f2); if [ -n \"$UUID\" ]; then nm-connection-editor --edit \"$UUID\"; else nm-connection-editor; fi"]
                  openEditorProcess.running = true
                }
              } 
            }
          }

          MouseArea {
            id: delegateMouse
            anchors.fill: parent
            acceptedButtons: Qt.NoButton // Lascia passare i click ai sotto-componenti (rotellina e connectArea)
            hoverEnabled: true
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
