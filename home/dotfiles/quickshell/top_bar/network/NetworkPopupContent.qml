import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Io
import "../../"

Item {
  id: contentRoot

  implicitHeight: mainLayout.implicitHeight
  implicitWidth: 350

  readonly property string spinnerIcon: ""

  property bool wifiEnabled: true
  property bool isScanning: false
  property bool isInitializing: true 
  property string currentConnectedSsid: ""
  property string currentConnectedSignal: ""

  property string selectedSsidForPassword: ""
  property bool showPasswordInput: false

  property string errorMessage: ""
  property string errorSsid: ""

  property var scanBuffer: ({})
  property string bufferedConnectedSsid: ""
  property string bufferedConnectedSignal: ""
  property var savedSsidsMap: ({})
  property var savedUuidsMap: ({})

  // Properties from NetworkWidget
  property string connectionType: "disconnected" 
  property string ssidName: ""
  property string ipAddress: "N/A"
  property real wifiStrength: 0
  property bool isConnecting: false
  readonly property bool isCurrentlyConnecting: contentRoot.isConnecting || connectProcess.running

  function resetState() {
    contentRoot.showPasswordInput = false
    contentRoot.errorMessage = ""
    contentRoot.errorSsid = ""
    contentRoot.selectedSsidForPassword = ""
  }

  // Initial read
  Component.onCompleted: {
    resetState()
    refreshNetworks(false) 
  }

  onVisibleChanged: {
    if (visible) {
      contentRoot.isInitializing = true
      refreshNetworks(false)
    } else {
      resetState()
    }
  }

  ListModel {
    id: wifiModel
  }

  function escapeShellArg(arg) {
    return "'" + arg.replace(/'/g, "'\\''") + "'"
  }

  function getWifiIcon(signalStr): string {
    let strength = parseInt(signalStr) || 0
    strength = Math.max(0, Math.min(100, strength))
    if (strength === 0) return "󰤯"
    if (strength <= 25) return "󰤟"
    if (strength <= 50) return "󰤢"
    if (strength <= 75) return "󰤥"
    return "󰤨"
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
    id: getSavedNetworks
    command: ["nmcli", "-t", "-f", "NAME,UUID,TYPE", "connection", "show"]
    property string accumulatedOutput: ""

    onRunningChanged: {
      if (running) {
        accumulatedOutput = ""
      } else {
        let lines = accumulatedOutput.trim().split("\n")
        let nameMap = {}
        let uuidMap = {}

        for (let l of lines) {
          let parts = l.split(":")

          if (parts.length >= 3 && parts[2].trim() === "802-11-wireless") {
            let cleanName = parts[0].trim()
            let cleanUuid = parts[1].trim()

            if (cleanName !== "") {
              nameMap[cleanName] = true
              uuidMap[cleanName] = cleanUuid
            }
          }
        }
        contentRoot.savedSsidsMap = nameMap
        contentRoot.savedUuidsMap = uuidMap
      }
    }

    stdout: SplitParser {
      onRead: data => {
        if (data) {
          getSavedNetworks.accumulatedOutput += data + "\n"
        }
      }
    }
  }

  Process {
    id: scanAndReadProcess
    command: ["sh", "-c", "nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi"]

    onRunningChanged: {
      if (running) {
        contentRoot.isScanning = true
        contentRoot.scanBuffer = {}
        contentRoot.bufferedConnectedSsid = ""
        contentRoot.bufferedConnectedSignal = ""
      } else {
        contentRoot.isScanning = false
        contentRoot.isInitializing = false 

        contentRoot.currentConnectedSsid = contentRoot.bufferedConnectedSsid
        contentRoot.currentConnectedSignal = contentRoot.bufferedConnectedSignal

        let foundSsids = contentRoot.scanBuffer
        let networksArray = []

        for (let ssid in foundSsids) {
          let isSaved = contentRoot.savedSsidsMap[ssid] === true

          networksArray.push({
            ssid: ssid,
            signal: foundSsids[ssid].signal,
            security: foundSsids[ssid].security,
            saved: isSaved
          })
        }

        networksArray.sort((a, b) => {
          let sigA = parseInt(a.signal) || 0
          let sigB = parseInt(b.signal) || 0
          return sigB - sigA
        })

        for (let i = wifiModel.count - 1; i >= 0; i--) {
          let existingSsid = wifiModel.get(i).ssid
          let exists = networksArray.find(n => n.ssid === existingSsid)
          if (!exists) {
            wifiModel.remove(i)
          }
        }

        for (let i = 0; i < networksArray.length; i++) {
          let net = networksArray[i]
          let existingIndex = -1

          for (let j = 0; j < wifiModel.count; j++) {
            if (wifiModel.get(j).ssid === net.ssid) {
              existingIndex = j
              break
            }
          }

          if (existingIndex !== -1) {
            let currentItem = wifiModel.get(existingIndex)

            if (currentItem.signal !== net.signal)
              wifiModel.setProperty(existingIndex, "signal", net.signal)
            if (currentItem.security !== net.security)
              wifiModel.setProperty(existingIndex, "security", net.security)
            if (currentItem.saved !== net.saved)
              wifiModel.setProperty(existingIndex, "saved", net.saved)

            if (existingIndex !== i) {
              wifiModel.move(existingIndex, i, 1)
            }
          } else {
            wifiModel.insert(i, {
              "ssid": net.ssid,
              "signal": net.signal,
              "security": net.security,
              "saved": net.saved
            })
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

          if (
            firstColon !== -1 &&
            lastColon !== -1 &&
            secondLastColon !== -1 &&
            firstColon < secondLastColon
          ) {
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
                let sigNum = parseInt(signal) || 0

                if (
                  !currentBuffer[ssid] ||
                  sigNum > (parseInt(currentBuffer[ssid].signal) || 0)
                ) {
                  currentBuffer[ssid] = {
                    "signal": signal,
                    "security": security
                  }
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
    
    onExited: {
      if (contentRoot.wifiEnabled) {
        turnOnDelay.restart()
      }
    }
  }

  // Wait for NIC to turn on
  Timer {
    id: turnOnDelay
    interval: 3500
    onTriggered: {
      refreshNetworks(true)
    }
  }

  Process {
    id: connectProcess
    command: ["sh", "-c", ""]

    onExited: (exitCode) => {
      getSavedNetworks.running = true
      refreshNetworks(false)

      if (exitCode !== 0) {
        contentRoot.errorMessage = "Connection failed. Wrong password?"
        contentRoot.errorSsid = contentRoot.selectedSsidForPassword
        contentRoot.showPasswordInput = true
      } else {
        resetState()
      }
    }
  }

  Process {
    id: openEditorProcess
    command: ["nm-connection-editor"]
  }

  // Refresh network data
  function refreshNetworks(forceRescan = false) {
    checkWifiStatus.running = true
    getSavedNetworks.running = true

    if (!scanAndReadProcess.running) {
      if (forceRescan) {
        scanAndReadProcess.command = ["sh", "-c", "nmcli device wifi rescan 2>/dev/null; sleep 0.5; nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi"]
      } else {
        scanAndReadProcess.command = ["sh", "-c", "nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi"]
      }
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
        color: settingsMouse.containsMouse
               ? Theme.widgetLightBackground
               : "transparent"

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
            StateManager.closeActivePopup()
          }
        }
      }
    }

    // Toggle Wi-Fi
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
          text: "Wi-Fi"
          font.bold: true
          font.pixelSize: Theme.fontSizeSmall
          color: Theme.barColor
          Layout.fillWidth: true
        }

        Rectangle {
          width: 40
          height: 22
          radius: 11
          color: contentRoot.wifiEnabled
                 ? Theme.colGreen
                 : Theme.barDarkColor

          Rectangle {
            width: 18
            height: 18
            radius: 9
            y: 2
            x: contentRoot.wifiEnabled ? 20 : 2
            color: "white"

            Behavior on x {
              NumberAnimation {
                duration: 150
              }
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor

            onClicked: {
              let willBeEnabled = !contentRoot.wifiEnabled
              contentRoot.wifiEnabled = willBeEnabled
              let newState = willBeEnabled ? "on" : "off"

              let cmd = "nmcli radio wifi " + newState
              toggleWifiProcess.command = ["sh", "-c", cmd]
              toggleWifiProcess.running = true

              resetState()

              if (!willBeEnabled) {
                wifiModel.clear()
                contentRoot.scanBuffer = {}
                contentRoot.bufferedConnectedSsid = ""
                contentRoot.bufferedConnectedSignal = ""
                contentRoot.savedSsidsMap = {}
                contentRoot.savedUuidsMap = {}
                contentRoot.isScanning = false
                contentRoot.isInitializing = false
              } else {
                wifiModel.clear()
                contentRoot.isInitializing = true
              }
            }
          }
        }
      }
    }

    //  Initial loader 
    Item {
      Layout.fillWidth: true
      Layout.preferredHeight: {
        let h = contentRoot.isInitializing && contentRoot.wifiEnabled ? 120 : 0
        return h
      }
      visible: contentRoot.isInitializing && contentRoot.wifiEnabled
      clip: true

      ColumnLayout {
        anchors.centerIn: parent
        spacing: 10

        Text {
          id: globalSpinner
          text: contentRoot.spinnerIcon
          font.pixelSize: 24
          color: Theme.barDarkColor
          Layout.alignment: Qt.AlignHCenter
          transformOrigin: Item.Center

          RotationAnimation on rotation {
            running: contentRoot.isInitializing && contentRoot.wifiEnabled
            from: 0
            to: 360
            duration: 1000
            loops: Animation.Infinite
          }
        }

        Text {
          text: "Loading network settings..."
          font.pixelSize: Theme.fontSizeSmall
          color: Theme.barDarkColor
          Layout.alignment: Qt.AlignHCenter
        }
      }
    }

    // Main content 
    ColumnLayout {
      id: mainContentCol
      Layout.fillWidth: true
      spacing: 14
      
      visible: {
        if (contentRoot.isInitializing && contentRoot.wifiEnabled) return false
        return contentRoot.wifiEnabled || contentRoot.connectionType === "ethernet"
      }

      // Password section
      ColumnLayout {
        id: passwordSection
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
          height: contentRoot.errorMessage ? 90 : 75
          radius: 8
          color: Theme.widgetLightBackground

          Behavior on height {
            NumberAnimation {
              duration: 150
            }
          }

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6

            RowLayout {
              Layout.fillWidth: true

              Text {
                text: contentRoot.selectedSsidForPassword
                font.pixelSize: Theme.barFontSizeSmall
                font.bold: true
                color: Theme.barColor
                elide: Text.ElideRight
                Layout.fillWidth: true
              }

              // Close password section
              Rectangle {
                width: 18
                height: 18
                radius: 4
                color: closePassMouse.containsMouse
                       ? Theme.barDarkColor
                       : "transparent"

                Text {
                  anchors.centerIn: parent
                  text: "✕"
                  font.pixelSize: 10
                  color: Theme.barColor
                }

                MouseArea {
                  id: closePassMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor

                  onClicked: {
                    resetState()
                  }
                }
              }
            }

            Text {
              text: contentRoot.errorMessage
              font.pixelSize: 9
              color: Theme.colRed
              visible: contentRoot.errorMessage !== ""
                       && contentRoot.errorSsid === contentRoot.selectedSsidForPassword
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: 8

              Rectangle {
                Layout.fillWidth: true
                height: 30
                radius: 6
                color: Theme.widgetDarkBackground
                border.color: contentRoot.errorMessage
                              ? Theme.colRed
                              : Theme.barDarkColor
                border.width: 1

                TextInput {
                  id: passwordInput
                  anchors.fill: parent
                  anchors.leftMargin: 8
                  anchors.rightMargin: 35
                  verticalAlignment: TextInput.AlignVCenter
                  font.pixelSize: Theme.fontSizeSmall
                  color: Theme.barColor
                  echoMode: passwordInput.showPassword
                            ? TextInput.Normal
                            : TextInput.Password

                  clip: true
                  property bool showPassword: false

                  Timer {
                    interval: 50
                    running: contentRoot.showPasswordInput
                    repeat: true

                    onTriggered: {
                      if (
                        contentRoot.showPasswordInput &&
                        !passwordInput.activeFocus
                      ) {
                        passwordInput.forceActiveFocus()
                      }
                    }
                  }

                  onAccepted: {
                    contentRoot.errorMessage = ""

                    let targetSsid = contentRoot.selectedSsidForPassword
                    if (targetSsid !== "") {
                      let updatedMap = contentRoot.savedSsidsMap
                      updatedMap[targetSsid] = true
                      contentRoot.savedSsidsMap = updatedMap
                    }

                    let cmd =
                      "nmcli dev wifi connect " +
                      contentRoot.escapeShellArg(targetSsid) +
                      " password " +
                      contentRoot.escapeShellArg(text)

                    contentRoot.showPasswordInput = false
                    connectProcess.command = ["sh", "-c", cmd]
                    connectProcess.running = true

                    text = ""
                  }
                }

                Text {
                  anchors.right: parent.right
                  anchors.rightMargin: 8
                  anchors.verticalCenter: parent.verticalCenter
                  text: passwordInput.showPassword ? "󰛐" : "󰈈"
                  font.pixelSize: 14
                  color: Theme.barColor
                  z: 2
                  visible: true 

                  MouseArea {
                    id: eyeMouse
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    z: 3

                    onClicked: {
                      passwordInput.showPassword = !passwordInput.showPassword
                    }
                  }
                }

                MouseArea {
                  anchors.fill: parent
                  acceptedButtons: Qt.NoButton

                  onClicked: {
                    passwordInput.forceActiveFocus()
                  }
                }
              }

              Rectangle {
                width: connectButtonText.width + 16
                height: 30
                radius: 6
                color: connectMouse.containsMouse
                       ? Theme.colGreen
                       : Theme.barDarkColor

                Text {
                  id: connectButtonText
                  anchors.centerIn: parent
                  text: "Connect"
                  font.pixelSize: Theme.barFontSizeSmall
                  font.bold: true
                  color: Theme.widgetDarkBackground
                }

                MouseArea {
                  id: connectMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor

                  onClicked: {
                    contentRoot.errorMessage = ""

                    let targetSsid = contentRoot.selectedSsidForPassword
                    if (targetSsid !== "") {
                      let updatedMap = contentRoot.savedSsidsMap
                      updatedMap[targetSsid] = true
                      contentRoot.savedSsidsMap = updatedMap
                    }

                    let cmd =
                      "nmcli dev wifi connect " +
                      contentRoot.escapeShellArg(targetSsid) +
                      " password " +
                      contentRoot.escapeShellArg(passwordInput.text)

                    contentRoot.showPasswordInput = false
                    connectProcess.command = ["sh", "-c", cmd]
                    connectProcess.running = true

                    passwordInput.text = ""
                  }
                }
              }
            }
          }
        }
      }

      // Current network, loading or connected 
      ColumnLayout {
        id: currentNetworkSection
        Layout.fillWidth: true
        spacing: 6

        visible: (
                   contentRoot.connectionType === "ethernet" ||
                   (contentRoot.connectionType === "wifi" && contentRoot.ssidName !== "") ||
                   isCurrentlyConnecting
                 ) && !contentRoot.showPasswordInput

        Text {
          text: isCurrentlyConnecting ? "Connecting..." : "Current network"
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
            spacing: 12

            Text {
              text: contentRoot.connectionType === "ethernet" ? "󰌗" : getWifiIcon(contentRoot.wifiStrength)
              font.pixelSize: 18
              color: isCurrentlyConnecting ? Theme.colYellow : Theme.colGreen
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 2

              Text {
                text: contentRoot.connectionType === "ethernet" ? "LAN" : (contentRoot.ssidName !== "" ? contentRoot.ssidName : contentRoot.selectedSsidForPassword)
                font.bold: true
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.barColor
                elide: Text.ElideRight
                Layout.fillWidth: true
              }

              Text {
                text: isCurrentlyConnecting ? "Establishing connection..." : contentRoot.ipAddress
                font.pixelSize: Theme.barFontSizeSmall
                color: isCurrentlyConnecting ? Theme.colYellow : Theme.barColor
              }
            }

            Text {
              id: spinnerIcon
              visible: isCurrentlyConnecting
              text: contentRoot.spinnerIcon 
              font.pixelSize: 24
              color: Theme.colYellow
              Layout.alignment: Qt.AlignVCenter
              horizontalAlignment: Text.AlignHCenter
              verticalAlignment: Text.AlignVCenter
              transformOrigin: Item.Center

              RotationAnimation on rotation {
                running: spinnerIcon.visible
                from: 0
                to: 360
                duration: 1000
                loops: Animation.Infinite
              }
            }
          }
        }
      }

      // Available networks
      ColumnLayout {
        id: availableNetworksSection
        Layout.fillWidth: true
        spacing: 6
        visible: contentRoot.wifiEnabled && contentRoot.connectionType !== "ethernet" 

        // Horizontal divider
        Rectangle {
          Layout.fillWidth: true
          Layout.topMargin: 4
          Layout.bottomMargin: 4
          height: 1
          color: Theme.barDarkColor
          opacity: 0.25
        }

        RowLayout {
          Layout.fillWidth: true
          Layout.minimumHeight: 24

          Text {
            text: "Available networks"
            font.pixelSize: Theme.fontSizeSmall
            font.bold: true
            color: Theme.barDarkColor
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
          }

          RowLayout {
            spacing: 6
            visible: contentRoot.isScanning
            Layout.alignment: Qt.AlignVCenter

            Text {
              text: "Scanning..."
              font.pixelSize: 10
              color: Theme.barDarkColor
            }

            Text {
              id: scanSpinner
              text: contentRoot.spinnerIcon
              font.pixelSize: 14
              color: Theme.barColor
              Layout.preferredWidth: 14
              Layout.preferredHeight: 14
              horizontalAlignment: Text.AlignHCenter
              verticalAlignment: Text.AlignVCenter
              transformOrigin: Item.Center

              RotationAnimation on rotation {
                running: contentRoot.isScanning
                from: 0
                to: 360
                duration: 1000
                loops: Animation.Infinite
              }
            }
          }

          Rectangle {
            width: 24
            height: 24
            radius: 4
            visible: !contentRoot.isScanning
            color: refreshMouse.containsMouse
                   ? Theme.widgetLightBackground
                   : "transparent"
            Layout.alignment: Qt.AlignVCenter

            Text {
              anchors.centerIn: parent
              text: "󰑐"
              font.pixelSize: Theme.fontSize
              color: Theme.barColor
            }

            MouseArea {
              id: refreshMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor

              onClicked: {
                refreshNetworks(true) 
              }
            }
          }
        }

        Text {
          text: "No networks found"
          font.pixelSize: Theme.fontSizeSmall
          color: Theme.barDarkColor

          visible: wifiModel.count === 0 &&
                   !contentRoot.isScanning

          Layout.topMargin: 8
          Layout.bottomMargin: 8
          Layout.alignment: Qt.AlignHCenter
        }

        ListView {
          id: wifiListView

          Layout.fillWidth: true
          Layout.preferredHeight: wifiModel.count > 0 ? Math.min(contentHeight, Screen.height * 0.45) : 0

          model: wifiModel
          clip: true
          spacing: 6

          delegate: Rectangle {
            required property string ssid
            required property string signal
            required property string security
            required property bool saved

            width: wifiListView.width
            height: 44
            radius: 8

            HoverHandler {
              id: delegateHover
            }

            color: delegateHover.hovered
                   ? Theme.widgetLightBackground
                   : "transparent"

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 12
              anchors.rightMargin: 12
              spacing: 10

              Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                RowLayout {
                  anchors.fill: parent
                  spacing: 10

                  Text {
                    text: getWifiIcon(signal)
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

                MouseArea {
                  id: connectArea
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor

                  onClicked: {
                    contentRoot.errorMessage = ""
                    contentRoot.errorSsid = ""
                    contentRoot.selectedSsidForPassword = ssid

                    let safeSsid = contentRoot.escapeShellArg(ssid)

                    if (security !== "" && security !== "--") {
                      if (saved) {
                        contentRoot.showPasswordInput = false
                        let cmd = "nmcli dev wifi connect " + safeSsid
                        connectProcess.command = ["sh", "-c", cmd]
                        connectProcess.running = true
                      } else {
                        contentRoot.showPasswordInput = true
                      }
                    } else {
                      contentRoot.showPasswordInput = false
                      let cmd = "nmcli dev wifi connect " + safeSsid
                        connectProcess.command = ["sh", "-c", cmd]
                        connectProcess.running = true
                    }
                  }
                }
              } 

              Rectangle {
                width: 24
                height: 24
                radius: 4

                color: editMouse.containsMouse
                       ? Theme.barDarkColor
                       : "transparent"

                visible: delegateHover.hovered && saved

                Text {
                  anchors.centerIn: parent
                  text: ""
                  font.pixelSize: Theme.barFontSize
                  color: editMouse.containsMouse
                       ? Theme.widgetLightBackground
                       : Theme.barColor
                }

                MouseArea {
                  id: editMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor

                  onClicked: mouse => {
                    mouse.accepted = true
                    let uuid = contentRoot.savedUuidsMap[ssid] || ""
                    let cmd = ""

                    if (uuid !== "") {
                      cmd = "nm-connection-editor --edit " + contentRoot.escapeShellArg(uuid)
                    } else {
                      cmd = "nm-connection-editor"
                    }

                    openEditorProcess.command = ["sh", "-c", cmd]
                    openEditorProcess.running = true
                    StateManager.closeActivePopup()
                  }
                }
              }
            
              Text {
                text: ""
                font.pixelSize: Theme.barFontSize
                color: Theme.barDarkColor
                visible: security !== "" && security !== "--"
              }            
            }
          }
        }
      }
    }
  }
}
