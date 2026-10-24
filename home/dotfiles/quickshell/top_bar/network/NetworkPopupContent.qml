import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import "../../"
import "NetworkModel.js" as NetworkModel

Item {
  id: root
  implicitWidth: 380
  implicitHeight: column.implicitHeight

  property string connectionType: "disconnected"
  property string ssidName: ""
  property string ipAddress: "N/A"
  property real wifiStrength: 0
  property bool isConnecting: false
  property var info: ({})
  property real downloadRate: 0
  property real uploadRate: 0

  property bool opened: true
  property string passwordSsid: ""
  property string passwordText: ""
  property string identityText: ""

  readonly property int fsTitle: Theme.fontSize                          
  readonly property int fsBody: Theme.fontSizeSmall                      
  readonly property int fsCaption: Theme.barFontSizeSmall                
  readonly property int fsIconHero: Math.round(Theme.fontSize * 1.5)     
  readonly property int fsIconRow: Theme.fontSize                        

  readonly property int rowPadding: 8

  property string prevIface: ""
  property real prevRxBytes: 0
  property real prevTxBytes: 0
  property real prevSampleTime: 0
  property var pingSamples: []   

  readonly property bool hasTransferStats: !!info && info.rx_bytes !== undefined
  readonly property var pingOkSamples: pingSamples.filter(function(v) { return v !== null })
  readonly property string pingText: {
    if (pingOkSamples.length === 0) return "--"
    let sum = 0
    for (let i = 0; i < pingOkSamples.length; i++) sum += pingOkSamples[i]
    return Math.round(sum / pingOkSamples.length) + " ms"
  }
  readonly property string packetLossText: pingSamples.length === 0
    ? "--"
    : Math.round((pingSamples.length - pingOkSamples.length) * 100 / pingSamples.length) + "%"

  function recordPing(next) {
    if (!next.iface) { pingSamples = []; return }
    if (next.internet_ping_ms === undefined) return
    let ms = parseFloat(next.internet_ping_ms)
    let samples = pingSamples.slice()
    samples.push(isFinite(ms) ? ms : null)
    while (samples.length > 10) samples.shift()
    pingSamples = samples
  }

  function updateDetails(raw) {
    let next = NetworkModel.parseKeyValue(raw)
    info = next

    let state = NetworkModel.throughputState({
      prevIface: prevIface,
      prevRxBytes: prevRxBytes,
      prevTxBytes: prevTxBytes,
      prevSampleTime: prevSampleTime
    }, next, Date.now() / 1000)

    prevIface = state.prevIface
    prevRxBytes = state.prevRxBytes
    prevTxBytes = state.prevTxBytes
    prevSampleTime = state.prevSampleTime
    downloadRate = state.downloadRate
    uploadRate = state.uploadRate
    recordPing(next)
  }

  Process {
    id: detailsProc
    command: ["bash", Qt.resolvedUrl("network_status.sh").toString().replace("file://", ""), "--verbose"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.updateDetails(text)
    }
  }

  Timer {
    id: detailsPoll
    interval: 1500
    repeat: true
    running: root.opened
    triggeredOnStart: true
    onTriggered: if (!detailsProc.running) detailsProc.running = true
  }

  readonly property bool networkManagerAvailable: Networking.backend === NetworkBackendType.NetworkManager
  readonly property var networkDevices: Networking.devices ? Networking.devices.values : []
  
  readonly property var wifiDevice: {
    let devs = networkDevices
    for (let i = 0; i < devs.length; i++) {
      if (devs[i] && devs[i].type === DeviceType.Wifi) return devs[i]
    }
    return null
  }

  onWifiDeviceChanged: {
    if (wifiDevice) wifiDevice.scannerEnabled = opened
  }
  
  onOpenedChanged: {
    if (wifiDevice) wifiDevice.scannerEnabled = opened
    if (opened) syncWifiNetworks()
  }

  Component.onCompleted: {
    if (wifiDevice) wifiDevice.scannerEnabled = true
    syncWifiNetworks()
  }

  readonly property var wifiNetworkObjects: wifiDevice && wifiDevice.networks ? wifiDevice.networks.values : []
  property var wifiNetworks: []

  function wifiIconFor(strength) {
    let icons = ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"]
    let index = Math.max(0, Math.min(4, Math.ceil(strength / 20) - 1))
    return icons[index]
  }

  function wifiRow(network) {
    if (!network) return null
    return {
      connected: !!network.connected,
      known: everConnected(network),
      ssid: network.name || "",
      signal: Math.round((network.signalStrength || 0) * 100),
      security: network.security,
      rawNetwork: network
    }
  }

  function sortWifiRows(rows) {
    let nets = Array.isArray(rows) ? rows.slice() : []
    nets.sort(function(a, b) {
      if (a.connected !== b.connected) return a.connected ? -1 : 1
      if (a.known !== b.known) return a.known ? -1 : 1
      return b.signal - a.signal
    })
    return nets
  }

  function formatBytes(bytes) {
    let n = Number(bytes)
    if (!isFinite(n) || n < 0) n = 0
    if (n < 1024) return Math.round(n) + " B"
    if (n < 1024 * 1024) return (n / 1024).toFixed(1) + " KB"
    if (n < 1024 * 1024 * 1024) return (n / (1024 * 1024)).toFixed(1) + " MB"
    return (n / (1024 * 1024 * 1024)).toFixed(2) + " GB"
  }

  function formatRate(bytesPerSec) {
    return formatBytes(bytesPerSec) + "/s"
  }

  function cancelPasswordPrompt() {
    passwordSsid = ""
    passwordText = ""
    identityText = ""
  }

  function openPasswordPrompt(ssid) {
    if (passwordSsid !== ssid) {
      passwordText = ""
      identityText = ""
    }
    passwordSsid = ssid
  }

  function requiresCredentials(security) {
    return security !== WifiSecurityType.Open && security !== WifiSecurityType.Owe
  }

  property var successfulUuids: ({})
  property bool timestampsLoaded: false

  function everConnected(network) {
    if (!network || !network.known) return false
    if (!timestampsLoaded || network.connected) return true
    let profiles = network.nmSettings
    if (!profiles) return true
    for (let i = 0; i < profiles.length; i++) {
      if (profiles[i] && successfulUuids[profiles[i].uuid]) return true
    }
    return false
  }

  function parseTimestamps(raw) {
    let map = ({})
    let any = false
    let lines = String(raw || "").split("\n")
    for (let i = 0; i < lines.length; i++) {
      let line = lines[i].trim()
      let idx = line.lastIndexOf(":")
      if (idx <= 0) continue
      any = true
      if (/^[1-9][0-9]*$/.test(line.substring(idx + 1))) map[line.substring(0, idx)] = true
    }
    if (!any) return
    successfulUuids = map
    timestampsLoaded = true
    syncWifiNetworks()
  }

  function refreshTimestamps() {
    if (!timestampProc.running) timestampProc.running = true
  }

  Process {
    id: timestampProc
    command: ["nmcli", "-t", "-f", "UUID,TIMESTAMP", "connection", "show"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseTimestamps(text)
    }
  }

  Timer {
    interval: 5000
    repeat: true
    running: root.opened
    triggeredOnStart: true
    onTriggered: root.refreshTimestamps()
  }

  property string wifiSignature: ""

  function rowsSignature(rows) {
    let withSignal = passwordSsid === ""
    return rows.map(function(r) {
      return r.ssid + "|" + (r.connected ? 1 : 0) + (r.known ? 1 : 0) + "|" + r.security + "|"
        + (withSignal ? Math.ceil(r.signal / 20) : "")
    }).join("\n")
  }

  function syncWifiNetworks() {
    let nets = []
    let networks = wifiNetworkObjects || []
    for (let i = 0; i < networks.length; i++) {
      let network = networks[i]
      if (!network) continue
      checkActionCompletion(network)
      let row = wifiRow(network)
      if (row) nets.push(row)
    }
    let sorted = sortWifiRows(nets)
    let signature = rowsSignature(sorted)
    if (signature === wifiSignature) return
    wifiSignature = signature
    wifiNetworks = sorted
  }

  onWifiNetworkObjectsChanged: syncWifiNetworks()

  Timer {
    interval: 2000
    running: root.opened
    repeat: true
    onTriggered: syncWifiNetworks()
  }

  property string actionKind: ""     // "connect" | "disconnect" | ""
  property string actionSsid: ""
  property string failureSsid: ""
  property string failureReason: ""
  readonly property bool busy: actionKind !== ""

  readonly property var connectionFailReasons: ({
    NoSecrets: ConnectionFailReason.NoSecrets,
    WifiAuthTimeout: ConnectionFailReason.WifiAuthTimeout,
    WifiNetworkLost: ConnectionFailReason.WifiNetworkLost,
    WifiClientDisconnected: ConnectionFailReason.WifiClientDisconnected,
    WifiClientFailed: ConnectionFailReason.WifiClientFailed
  })

  readonly property string enterpriseConnectScript:
    "u=$(uuidgen); IFS= read -r pw;" +
    " nmcli connection add type wifi con-name \"$1\" ssid \"$1\" connection.uuid \"$u\"" +
    " wifi-sec.key-mgmt wpa-eap 802-1x.eap peap 802-1x.phase2-auth mschapv2" +
    " 802-1x.identity \"$2\" 802-1x.auth-timeout 8 >/dev/null" +
    " && printf 'set 802-1x.password %s\\nsave\\nquit\\n' \"$pw\" | nmcli connection edit uuid \"$u\" >/dev/null" +
    " && nmcli connection up uuid \"$u\"" +
    " || { nmcli connection delete uuid \"$u\" >/dev/null 2>&1; false; }"

  function networkForSsid(ssid) {
    let networks = wifiNetworkObjects || []
    for (let i = 0; i < networks.length; i++) {
      if (networks[i] && networks[i].name === ssid) return networks[i]
    }
    return null
  }

  function runNetworkAction(kind, network, callback) {
    if (actionKind !== "" || !network) return
    actionSsid = network.name || ""
    actionKind = kind
    failureSsid = ""
    failureReason = ""
    callback(network)
    actionTimeout.restart()
  }

  function clearNetworkAction() {
    actionTimeout.stop()
    if (actionKind === "connect") {
      cancelPasswordPrompt()
      refreshTimestamps()
    }
    failureSsid = ""
    failureReason = ""
    actionSsid = ""
    actionKind = ""
    Qt.callLater(syncWifiNetworks)
  }

  function failNetworkAction(network, reason) {
    if (!network || actionKind === "" || actionSsid !== (network.name || "")) return
    actionTimeout.stop()
    failureSsid = actionSsid
    failureReason = networkFailureReason(reason, requiresCredentials(network.security))
    actionSsid = ""
    actionKind = ""
    Qt.callLater(syncWifiNetworks)
  }

  function networkFailureReason(reason, needsCredentials) {
    let r = connectionFailReasons
    if (needsCredentials && reason === r.NoSecrets) return "Passphrase required"
    if (needsCredentials && reason === r.WifiAuthTimeout) return "Wrong password"
    if (reason === r.WifiNetworkLost) return "Network lost"
    if (reason === r.WifiClientDisconnected) return "Disconnected"
    if (reason === r.WifiClientFailed) return "Connection failed"
    return "Failed to connect"
  }

  function shouldRepromptPassphrase(reason, needsCredentials) {
    if (!needsCredentials) return false
    return reason === connectionFailReasons.NoSecrets || reason === connectionFailReasons.WifiAuthTimeout
  }

  function checkActionCompletion(network) {
    if (!network || actionKind === "" || actionSsid !== (network.name || "")) return
    if (actionKind === "connect" && network.connected) clearNetworkAction()
    else if (actionKind === "disconnect" && !network.connected && !network.stateChanging) clearNetworkAction()
  }

  function handleConnectionFailed(network, reason) {
    let ours = actionKind === "connect" && actionSsid === (network.name || "")
    failNetworkAction(network, reason)
    if (ours && shouldRepromptPassphrase(reason, requiresCredentials(network.security)))
      openPasswordPrompt(network.name || "")
  }

  function connectDirectly(ssid) {
    runNetworkAction("connect", networkForSsid(ssid), function(network) { network.connect() })
  }

  function connectWithPassphrase(ssid, passphrase) {
    runNetworkAction("connect", networkForSsid(ssid), function(network) { network.connectWithPsk(passphrase) })
  }

  function connectEnterprise(ssid, identity, passphrase) {
    runNetworkAction("connect", networkForSsid(ssid), function(network) {
      enterpriseConnect.secret = passphrase
      enterpriseConnect.command = ["bash", "-c", enterpriseConnectScript, "nmcli-eap", ssid, identity]
      enterpriseConnect.running = true
    })
  }

  function disconnectRow(ssid) {
    runNetworkAction("disconnect", networkForSsid(ssid), function(network) { network.disconnect() })
  }

  Instantiator {
    model: root.wifiNetworkObjects
    delegate: Connections {
      required property var modelData
      target: modelData
      function onConnectionFailed(reason) { root.handleConnectionFailed(modelData, reason) }
      function onConnectedChanged() { root.checkActionCompletion(modelData) }
      function onKnownChanged() { root.checkActionCompletion(modelData) }
      function onStateChangingChanged() { root.checkActionCompletion(modelData) }
    }
  }

  Process {
    id: enterpriseConnect
    property string secret: ""
    stdinEnabled: true
    onStarted: {
      write(secret + "\n")
      secret = ""
    }
    onExited: function(exitCode, exitStatus) {
      if (exitCode === 0 || root.actionKind !== "connect") return
      actionTimeout.stop()
      root.failureSsid = root.actionSsid
      root.failureReason = "Connection failed"
      root.actionSsid = ""
      root.actionKind = ""
    }
  }

  Timer {
    id: actionTimeout
    interval: 30000
    repeat: false
    onTriggered: {
      if (!root.actionKind) return
      root.failureSsid = root.actionSsid
      root.failureReason = root.actionKind === "connect" ? "Timed out connecting" : "Timed out disconnecting"
      root.actionSsid = ""
      root.actionKind = ""
      root.syncWifiNetworks()
    }
  }

  Process {
    id: openEditorProcess
    command: ["nm-connection-editor"]
  }

  Column {
    id: column
    width: parent.width
    spacing: 12

    // --- HERO SECTION ---
    Item {
      width: parent.width
      height: 48

      RowLayout {
        anchors.fill: parent
        spacing: 12

        Text {
          text: root.connectionType === "ethernet" ? "󰈀" : wifiIconFor(root.wifiStrength)
          font.family: Theme.fontFamily
          font.pixelSize: root.fsIconHero
          color: Theme.barColor
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 2

          Text {
            text: root.connectionType === "ethernet" ? "LAN" : (root.ssidName !== "" ? root.ssidName : (root.info.ip ? (root.info.ssid || "Connected") : "Disconnected"))
            font.family: Theme.fontFamily
            font.pixelSize: root.fsTitle
            font.bold: true
            color: Theme.barColor
            elide: Text.ElideRight
            Layout.fillWidth: true
          }

          Text {
            text: !Networking.wifiEnabled ? "WIFI OFF" : (isConnecting ? "CONNECTING..." : ((root.connectionType !== "disconnected" || root.info.ip) ? "CONNECTED" : "NO CONNECTION"))
            font.family: Theme.fontFamily
            font.pixelSize: root.fsCaption
            font.bold: true
            color: Theme.colMuted
          } 
        }

        // Wifi Power Toggle Switch
        Rectangle {
          width: 36; height: 20; radius: 10
          color: Networking.wifiEnabled ? Theme.colGreen : Theme.widgetLightBackground
          Rectangle {
            width: 16; height: 16; radius: 8; y: 2
            x: Networking.wifiEnabled ? 18 : 2
            color: "white"
            Behavior on x { NumberAnimation { duration: 150 } }
          }
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
          }
        }
      }
    }

    // --- STATS GRID ---
    GridLayout {
      width: parent.width
      columns: 4
      columnSpacing: 12
      rowSpacing: 6

      Text { text: "Ping"; color: Theme.colMuted; font.family: Theme.fontFamily; font.pixelSize: root.fsBody }
      Text { text: root.pingText; color: Theme.barColor; font.family: Theme.fontFamily; font.pixelSize: root.fsBody; font.bold: true; horizontalAlignment: Text.AlignRight; Layout.fillWidth: true }
      Text { text: "Packet Loss"; color: Theme.colMuted; font.family: Theme.fontFamily; font.pixelSize: root.fsBody }
      Text { text: root.packetLossText; color: Theme.barColor; font.family: Theme.fontFamily; font.pixelSize: root.fsBody; font.bold: true; horizontalAlignment: Text.AlignRight; Layout.fillWidth: true }

      Text { text: "Receiving"; color: Theme.colMuted; font.family: Theme.fontFamily; font.pixelSize: root.fsBody }
      Text { text: root.hasTransferStats ? formatRate(root.downloadRate) : "--"; color: Theme.barColor; font.family: Theme.fontFamily; font.pixelSize: root.fsBody; font.bold: true; horizontalAlignment: Text.AlignRight; Layout.fillWidth: true }
      Text { text: "Sending"; color: Theme.colMuted; font.family: Theme.fontFamily; font.pixelSize: root.fsBody }
      Text { text: root.hasTransferStats ? formatRate(root.uploadRate) : "--"; color: Theme.barColor; font.family: Theme.fontFamily; font.pixelSize: root.fsBody; font.bold: true; horizontalAlignment: Text.AlignRight; Layout.fillWidth: true }

      Text { text: "Downloaded"; color: Theme.colMuted; font.family: Theme.fontFamily; font.pixelSize: root.fsBody }
      Text { text: root.hasTransferStats ? formatBytes(root.info.rx_bytes) : "--"; color: Theme.barColor; font.family: Theme.fontFamily; font.pixelSize: root.fsBody; font.bold: true; horizontalAlignment: Text.AlignRight; Layout.fillWidth: true }
      Text { text: "Uploaded"; color: Theme.colMuted; font.family: Theme.fontFamily; font.pixelSize: root.fsBody }
      Text { text: root.hasTransferStats ? formatBytes(root.info.tx_bytes) : "--"; color: Theme.barColor; font.family: Theme.fontFamily; font.pixelSize: root.fsBody; font.bold: true; horizontalAlignment: Text.AlignRight; Layout.fillWidth: true }

      Text { text: "IP"; color: Theme.colMuted; font.family: Theme.fontFamily; font.pixelSize: root.fsBody }
      Text { text: root.ipAddress; color: Theme.barColor; font.family: Theme.fontFamily; font.pixelSize: root.fsBody; font.bold: true; horizontalAlignment: Text.AlignRight; Layout.fillWidth: true }
      Text { text: "Gateway"; color: Theme.colMuted; font.family: Theme.fontFamily; font.pixelSize: root.fsBody }
      Text { text: root.info && root.info.gateway ? root.info.gateway : "N/A"; color: Theme.barColor; font.family: Theme.fontFamily; font.pixelSize: root.fsBody; font.bold: true; horizontalAlignment: Text.AlignRight; Layout.fillWidth: true }
    }

    // --- DIVIDER ---
    Rectangle { width: parent.width; height: 1; color: Theme.widgetLightBackground; visible: Networking.wifiEnabled}

    // --- WIFI NETWORKS LIST ---
    ListView {
      id: wifiListView
      width: parent.width
      height: Math.min(contentHeight, 280)
      model: root.wifiNetworks
      clip: true
      spacing: 4
      visible: Networking.wifiEnabled

      section.property: "known"
      section.criteria: ViewSection.FullString
      section.delegate: Item {
        width: wifiListView.width
        height: 24
        Text {
          anchors.bottom: parent.bottom
          anchors.bottomMargin: root.rowPadding / 2
          text: section === "true" ? "KNOWN NETWORKS" : "OTHER NETWORKS"
          font.family: Theme.fontFamily
          font.pixelSize: root.fsCaption
          font.bold: true
          color: Theme.colMuted
        }
      }

      delegate: Rectangle {
        id: row
        required property var modelData

        readonly property string ssid: modelData.ssid
        readonly property bool isConnected: modelData.connected
        readonly property bool isKnown: modelData.known
        readonly property bool needsCredentials: root.requiresCredentials(modelData.security)
        readonly property bool isEnterprise: modelData.security === WifiSecurityType.Wpa2Eap
          || modelData.security === WifiSecurityType.WpaEap

        readonly property bool isBusy: root.actionKind !== "" && root.actionSsid === ssid
        readonly property bool isFailed: root.failureReason !== "" && root.failureSsid === ssid
        readonly property bool isPasswordOpen: root.passwordSsid !== "" && root.passwordSsid === ssid

        readonly property string statusText: {
          if (isPasswordOpen) return ""
          if (isBusy && root.actionKind === "connect") return "Connecting\u2026"
          if (isBusy && root.actionKind === "disconnect") return "Disconnecting\u2026"
          if (isFailed) return root.failureReason
          if (isConnected) return "Connected"
          return ""
        }
        readonly property color statusColor: isFailed ? Theme.colRed : (isBusy ? Theme.barColor : Theme.colMuted)

        function submitCredentials() {
          if (root.busy || root.passwordText.length === 0) return
          if (!isEnterprise) return root.connectWithPassphrase(ssid, root.passwordText)
          if (root.identityText.length > 0) root.connectEnterprise(ssid, root.identityText, root.passwordText)
        }

        width: wifiListView.width
        implicitHeight: root.rowPadding + rowContent.implicitHeight + root.rowPadding
          + (isPasswordOpen ? root.rowPadding + passwordPanel.implicitHeight : 0)
        height: implicitHeight
        radius: Theme.radiusInner
        color: delegateHover.hovered || isConnected || isPasswordOpen ? Theme.widgetLightBackground : "transparent"

        HoverHandler { id: delegateHover }

        RowLayout {
          id: rowContent
          anchors.top: parent.top
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.margins: root.rowPadding
          spacing: 10

          Text {
            text: wifiIconFor(modelData.signal)
            font.family: Theme.fontFamily
            font.pixelSize: root.fsIconRow
            color: row.isFailed ? Theme.colRed : Theme.barColor
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
              text: modelData.ssid || "Hidden Network"
              font.family: Theme.fontFamily
              font.pixelSize: root.fsBody
              font.bold: modelData.connected
              color: Theme.barColor
              elide: Text.ElideRight
              Layout.fillWidth: true
            }

            Text {
              visible: row.statusText !== ""
              text: row.statusText
              font.family: Theme.fontFamily
              font.pixelSize: root.fsCaption
              color: row.statusColor
              elide: Text.ElideRight
              Layout.fillWidth: true
            }
          }

          Rectangle {
            id: editConnection
            width: 24; height: 24; radius: 4
            color: editMouse.containsMouse ? Theme.colMuted : "transparent"
            visible: modelData.known

            readonly property string profileUuid: {
              let net = modelData.rawNetwork
              let profiles = net ? net.nmSettings : null
              return (profiles && profiles.length > 0 && profiles[0]) ? profiles[0].uuid : ""
            }

            Text {
              anchors.centerIn: parent
              text: ""
              font.family: Theme.fontFamily
              font.pixelSize: root.fsBody
              color: Theme.barColor
            }

            MouseArea {
              id: editMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                mouse.accepted = true
                openEditorProcess.command = ["nm-connection-editor", "--edit", editConnection.profileUuid]
                openEditorProcess.running = true
              }
            }
          }

          Text {
            text: ""
            font.family: Theme.fontFamily
            font.pixelSize: root.fsCaption
            color: Theme.colMuted
            visible: row.needsCredentials && !modelData.known
          }
        }

        MouseArea {
          id: rowMouse
          anchors.top: parent.top
          anchors.left: parent.left
          anchors.right: parent.right
          height: rowContent.implicitHeight + 2 * root.rowPadding
          cursorShape: Qt.PointingHandCursor
          enabled: !root.busy && !editMouse.containsMouse
          onClicked: {
            if (row.isConnected) {
              root.disconnectRow(row.ssid)
              return
            }
            if (row.needsCredentials && !row.isKnown) {
              root.openPasswordPrompt(row.ssid)
              return
            }
            root.connectDirectly(row.ssid)
          }
        }

        Timer {
          id: failureTimer
          interval: 2000
          running: row.isFailed && row.isPasswordOpen
          onTriggered: {
            root.failureSsid = ""
            root.failureReason = ""
            pwInput.forceActiveFocus()
          }
        }

        Timer {
          interval: 50
          repeat: true
          running: row.isPasswordOpen && !row.isBusy && !row.isFailed
            && !pwInput.activeFocus && !idInput.activeFocus
          onTriggered: {
            if (row.isEnterprise && idInput.text.length === 0) idInput.forceActiveFocus()
            else pwInput.forceActiveFocus()
          }
        }

        ColumnLayout {
          id: passwordPanel
          visible: row.isPasswordOpen
          anchors.top: rowContent.bottom
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.margins: root.rowPadding
          spacing: root.rowPadding

          // Identity (only for 802.1X networks)
          Rectangle {
            id: idBox
            visible: row.isEnterprise && !row.isBusy && !row.isFailed
            Layout.fillWidth: true
            implicitHeight: idInput.implicitHeight + 2 * root.rowPadding
            radius: Theme.radiusInner
            color: Theme.widgetDarkBackground
            border.width: 1
            border.color: idInput.activeFocus ? Theme.accent1 : Theme.barDarkColor

            TextInput {
              id: idInput
              anchors.fill: parent
              anchors.margins: root.rowPadding
              verticalAlignment: TextInput.AlignVCenter
              clip: true
              color: Theme.barColor
              font.family: Theme.fontFamily
              font.pixelSize: root.fsBody
              enabled: !row.isBusy
              text: row.isPasswordOpen ? root.identityText : ""

              onAccepted: pwInput.forceActiveFocus()
              onTextChanged: if (row.isPasswordOpen && text !== root.identityText) root.identityText = text
              Keys.onEscapePressed: root.cancelPasswordPrompt()

              Text {
                visible: idInput.text.length === 0
                anchors.verticalCenter: parent.verticalCenter
                text: "Identity"
                color: Theme.colMuted
                font.family: Theme.fontFamily
                font.pixelSize: root.fsBody
              }
            }
          }

          // Password + confirm button
          RowLayout {
            visible: !row.isBusy && !row.isFailed
            Layout.fillWidth: true
            spacing: root.rowPadding

            Rectangle {
              id: pwBox
              Layout.fillWidth: true
              implicitHeight: pwInput.implicitHeight + 2 * root.rowPadding
              radius: Theme.radiusInner
              color: Theme.widgetDarkBackground
              border.width: 1
              border.color: pwInput.activeFocus ? Theme.accent1 : Theme.barDarkColor

              TextInput {
                id: pwInput
                anchors.fill: parent
                anchors.margins: root.rowPadding
                verticalAlignment: TextInput.AlignVCenter
                clip: true
                echoMode: TextInput.Password
                color: Theme.barColor
                font.family: Theme.fontFamily
                font.pixelSize: root.fsBody
                enabled: !row.isBusy
                text: row.isPasswordOpen ? root.passwordText : ""

                onAccepted: row.submitCredentials()
                onTextChanged: if (row.isPasswordOpen && text !== root.passwordText) root.passwordText = text
                Keys.onEscapePressed: root.cancelPasswordPrompt()

                Text {
                  visible: pwInput.text.length === 0
                  anchors.verticalCenter: parent.verticalCenter
                  text: "Passphrase"
                  color: Theme.colMuted
                  font.family: Theme.fontFamily
                  font.pixelSize: root.fsBody
                }
              }
            }

            Rectangle {
              id: connectBtn
              readonly property bool ready: pwInput.text.length > 0
                && (!row.isEnterprise || idInput.text.length > 0)
              Layout.preferredWidth: pwBox.implicitHeight
              Layout.preferredHeight: pwBox.implicitHeight
              radius: Theme.radiusInner
              color: ready && connectMouse.containsMouse ? Theme.colGreen : Theme.barDarkColor
              opacity: ready ? 1 : 0.4

              Text {
                anchors.centerIn: parent
                text: "󰄬"
                font.family: Theme.fontFamily
                font.pixelSize: root.fsBody
                color: connectBtn.ready && connectMouse.containsMouse ? Theme.widgetDarkBackground : Theme.barColor
              }

              MouseArea {
                id: connectMouse
                anchors.fill: parent
                hoverEnabled: true
                enabled: connectBtn.ready
                cursorShape: Qt.PointingHandCursor
                onClicked: row.submitCredentials()
              }
            }
          }

          // Status
          Rectangle {
            visible: row.isBusy || row.isFailed
            Layout.fillWidth: true
            implicitHeight: pwBox.implicitHeight
            radius: Theme.radiusInner
            color: Theme.widgetDarkBackground
            border.width: 1
            border.color: row.isFailed ? Theme.colRed : Theme.barDarkColor

            Text {
              anchors.centerIn: parent
              text: row.isFailed ? "Wrong password" : "Connecting\u2026"
              font.family: Theme.fontFamily
              font.pixelSize: root.fsBody
              color: row.isFailed ? Theme.colRed : Theme.barColor
            }
          }
        }
      }
    }
  }
}
