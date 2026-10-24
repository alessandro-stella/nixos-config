import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import "../.."
import "AudioModel.js" as AudioModel

Scope {
  id: popupScope

  required property Item targetItem
  required property PanelWindow parentWindow

  property bool isOpen: false
  property bool _isLoaded: false

  function toggle() {
    if (!isOpen) {
      _isLoaded = true
      StateManager.requestOpen(popupScope)
    } else {
      StateManager.requestClose(popupScope)
    }
  }

  Loader {
    id: popupLoader
    active: popupScope._isLoaded
    sourceComponent: popupContentComponent

    onLoaded: {
      if (item) {
        item.isOpen = popupScope.isOpen
      }
    }
  }

  Connections {
    target: popupScope
    function onIsOpenChanged() {
      if (popupLoader.item && popupLoader.item.isOpen !== popupScope.isOpen) {
        popupLoader.item.isOpen = popupScope.isOpen
      }
    }
  }

  component AudioSlider: Item {
    id: sl

    property real minimum: 0
    property real maximum: 1
    property real step: 0.05
    property real value: 0
    property bool dragging: false
    property real liveValue: 0

    signal moved(real v)
    signal rightClicked()

    readonly property real shown: dragging ? liveValue : value
    readonly property real ratio: maximum > minimum
      ? Math.max(0, Math.min(1, (shown - minimum) / (maximum - minimum)))
      : 0

    implicitHeight: 20

    Rectangle {
      id: track
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width
      height: 6
      radius: 3
      color: Theme.widgetLightBackground

      Rectangle {
        width: parent.width * sl.ratio
        height: parent.height
        radius: 3
        color: Theme.barColor
      }
    }

    Rectangle {
      width: 14
      height: 14
      radius: 7
      anchors.verticalCenter: parent.verticalCenter
      x: sl.ratio * (sl.width - width)
      color: Theme.barColor
    }

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      preventStealing: true
      cursorShape: Qt.PointingHandCursor

      function apply(mx) {
        var r = Math.max(0, Math.min(1, mx / sl.width))
        var v = sl.minimum + r * (sl.maximum - sl.minimum)
        v = Math.round(v / sl.step) * sl.step
        v = Math.max(sl.minimum, Math.min(sl.maximum, v))
        sl.liveValue = v
        sl.moved(v)
      }

      onPressed: function(mouse) {
        if (mouse.button === Qt.RightButton) {
          sl.rightClicked()
          return
        }
        sl.dragging = true
        apply(mouse.x)
      }
      onPositionChanged: function(mouse) {
        if (pressed && sl.dragging) apply(mouse.x)
      }
      onReleased: sl.dragging = false
      onCanceled: sl.dragging = false
    }
  }

  component AudioSwitch: Rectangle {
    id: sw

    property bool checked: false
    signal toggled()

    width: 37
    height: 20
    radius: 10
    color: checked ? Theme.colGreen : Theme.widgetLightBackground

    Rectangle {
      width: 16
      height: 16
      radius: 8
      y: 2
      x: sw.checked ? 19 : 2
      color: "white"
      Behavior on x { NumberAnimation { duration: Theme.fastAnimation } }
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: sw.toggled()
    }
  }

  component AudioSectionHeader: Text {
    textFormat: Text.PlainText
    font.family: Theme.fontFamily
    font.pixelSize: Theme.barFontSizeSmall
    font.bold: true
    font.letterSpacing: 1.2
    font.capitalization: Font.AllUppercase
    color: Theme.colMuted
  }

  component AudioSeparator: Rectangle {
    width: parent ? parent.width : 0
    height: 2
    color: Theme.widgetLightBackground
  }

  component DeviceRow: Rectangle {
    id: dr

    property string glyph: ""
    property string label: ""
    property bool active: false
    signal clicked()

    implicitHeight: drInner.implicitHeight + 16
    radius: Theme.radiusInner
    color: active
      ? Qt.rgba(Theme.barColor.r, Theme.barColor.g, Theme.barColor.b, 0.14)
      : (drHover.hovered
        ? Qt.rgba(Theme.barColor.r, Theme.barColor.g, Theme.barColor.b, 0.08)
        : "transparent")

    HoverHandler { id: drHover }

    Row {
      id: drInner
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: 6
      anchors.rightMargin: 6
      spacing: 8

      Text {
        textFormat: Text.PlainText
        text: dr.glyph
        color: Theme.barColor
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        width: 22
        horizontalAlignment: Text.AlignHCenter
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        textFormat: Text.PlainText
        text: dr.label
        color: Theme.barColor
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall
        font.bold: dr.active
        elide: Text.ElideRight
        width: parent.width - 22 - 8
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: dr.clicked()
    }
  }

  // ---------------------------------------------------------------------
  // Popup
  // ---------------------------------------------------------------------

  Component {
    id: popupContentComponent

    GenericPopup {
      id: genericPopup

      parentWindow: popupScope.parentWindow
      targetItem: popupScope.targetItem
      popupWidth: 380

      onIsOpenChanged: {
        if (popupScope.isOpen !== isOpen) {
          popupScope.isOpen = isOpen
        }
      }

      contentComponent: Component {
        Item {
          id: content

          // -----PipeWire data -----
          readonly property var sink: Pipewire.defaultAudioSink
          readonly property var source: Pipewire.defaultAudioSource
          readonly property var nodes: Pipewire.nodes ? Pipewire.nodes.values : []
          readonly property var mprisPlayers: Mpris.players ? Mpris.players.values : []

          readonly property var candidateSinks: {
            var list = []
            for (var i = 0; i < nodes.length; i++) {
              var n = nodes[i]
              if (!n || !n.isSink || n.isStream || AudioModel.isHiddenNode(n)) continue
              list.push(n)
            }
            return list
          }

          readonly property var candidateSources: {
            var list = []
            for (var i = 0; i < nodes.length; i++) {
              var n = nodes[i]
              if (!n || n.isSink || n.isStream) continue
              if (!AudioModel.isAudioSource(n)) continue
              if (n.name === "quickshell" || AudioModel.isHiddenNode(n)) continue
              list.push(n)
            }
            return list
          }

          readonly property var candidateStreams: {
            var list = []
            for (var i = 0; i < nodes.length; i++) {
              var n = nodes[i]
              if (!n || !n.isStream || !AudioModel.isPlaybackStream(n)) continue
              list.push(n)
            }
            return list
          }

          readonly property var audioSinks: {
            var list = candidateSinks.slice()
            if (sink && list.indexOf(sink) < 0) list.unshift(sink)
            return list
          }

          readonly property var audioSources: {
            var list = candidateSources.slice()
            if (source && list.indexOf(source) < 0) list.unshift(source)
            return list
          }

          readonly property var audioStreams: {
            var list = []
            for (var i = 0; i < candidateStreams.length; i++)
              if (candidateStreams[i].audio) list.push(candidateStreams[i])
            return list
          }

          property var displaySinks: []
          property var displaySources: []
          property var displayStreams: []

          function nodeFor(row) {
            if (!row) return null
            for (var i = 0; i < nodes.length; i++) {
              var n = nodes[i]
              if (n && n.id === row.id && String(n.name || "") === row.name) return n
            }
            return null
          }

          function refreshDisplay() {
            displaySinks = AudioModel.rowSnapshot(audioSinks)
            displaySources = AudioModel.rowSnapshot(audioSources)
            displayStreams = AudioModel.rowSnapshot(audioStreams)
          }

          onAudioSinksChanged: refreshTimer.restart()
          onAudioSourcesChanged: refreshTimer.restart()
          onAudioStreamsChanged: refreshTimer.restart()
          Component.onCompleted: refreshDisplay()

          Timer {
            id: refreshTimer
            interval: 75
            repeat: false
            onTriggered: content.refreshDisplay()
          }

          PwObjectTracker { objects: content.candidateSinks }
          PwObjectTracker { objects: content.candidateSources }
          PwObjectTracker { objects: content.candidateStreams }

          PwNodePeakMonitor {
            id: inputPeakMonitor
            node: content.source
            enabled: !!content.source
          }

          // ----- Derived state -----
          readonly property real outputVolume: sink && sink.audio ? sink.audio.volume : 0
          readonly property bool outputMuted: sink && sink.audio ? sink.audio.muted : false
          readonly property real inputVolume: source && source.audio ? source.audio.volume : 0
          readonly property bool inputMuted: source && source.audio ? source.audio.muted : false

          readonly property bool hasOutput: !!(sink && sink.audio)
          readonly property bool hasInput: !!(source && source.audio)
          readonly property bool anyAudible: (hasOutput && !outputMuted) || (hasInput && !inputMuted)

          function outputIcon() {
            if (!hasOutput) return "\uf026"
            if (AudioModel.isHeadphones(sink)) return "󰋋"
            if (outputMuted) return "󰝟"
            if (outputVolume >= 0.5) return "\uf028"
            if (outputVolume > 0) return "\uf027"
            return "\uf026"
          }

          function setOutputVolume(v) {
            if (!hasOutput) return
            sink.audio.volume = Math.max(0, Math.min(1, v))
          }

          function setInputVolume(v) {
            if (!hasInput) return
            source.audio.volume = Math.max(0, Math.min(1, v))
          }

          function toggleOutputMute() {
            if (hasOutput) sink.audio.muted = !sink.audio.muted
          }

          function toggleInputMute() {
            if (hasInput) source.audio.muted = !source.audio.muted
          }

          function toggleAllMuted() {
            var mute = anyAudible
            if (hasOutput) sink.audio.muted = mute
            if (hasInput) source.audio.muted = mute
          }

          function setDefaultSink(node) {
            if (node) Pipewire.preferredDefaultAudioSink = node
          }

          function setDefaultSource(node) {
            if (node && node.audio) Pipewire.preferredDefaultAudioSource = node
          }

          function streamIsPlaying(node) {
            for (var i = 0; i < mprisPlayers.length; i++) {
              var p = mprisPlayers[i]
              if (p && p.isPlaying && AudioModel.streamRepresentsPlayer(node, p, mprisPlayers, audioStreams))
                return true
            }
            return false
          }

          // ----- Size -----
          readonly property real maxHeight: Math.min(560, Screen.height - 160)

          implicitWidth: 352
          implicitHeight: Math.min(panelColumn.implicitHeight, maxHeight)

          ScrollView {
            id: scrollArea
            anchors.fill: parent
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: panelColumn.implicitHeight > height
              ? ScrollBar.AsNeeded
              : ScrollBar.AlwaysOff

            Column {
              id: panelColumn
              width: scrollArea.availableWidth
              spacing: 14

              // ---------- Hero ----------
              Item {
                width: parent.width
                implicitHeight: Math.max(heroIcon.implicitHeight, heroLabels.implicitHeight, powerSwitch.implicitHeight)
                height: implicitHeight

                Text {
                  id: heroIcon
                  textFormat: Text.PlainText
                  text: content.outputIcon()
                  color: Theme.barColor
                  font.family: Theme.fontFamily
                  font.pixelSize: Math.round(Theme.fontSize * 2.5)
                  opacity: content.outputMuted ? 0.5 : 1.0
                  anchors.left: parent.left
                  anchors.verticalCenter: parent.verticalCenter
                }

                AudioSwitch {
                  id: powerSwitch
                  checked: content.anyAudible
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  onToggled: content.toggleAllMuted()
                }

                Column {
                  id: heroLabels
                  anchors.left: heroIcon.right
                  anchors.leftMargin: 14
                  anchors.right: parent.right
                  anchors.rightMargin: powerSwitch.width + 12
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: 2

                  Text {
                    text: "Audio"
                    textFormat: Text.PlainText
                    color: Theme.barColor
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.bold: true
                    elide: Text.ElideRight
                    width: parent.width
                  }

                  Text {
                    textFormat: Text.PlainText
                    text: AudioModel.outputVolumeName(
                      outputSlider.dragging ? outputSlider.liveValue : content.outputVolume,
                      content.outputMuted
                    ).toUpperCase()
                    color: Qt.darker(Theme.barColor, 1.4)
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.barFontSizeSmall
                    font.bold: true
                    font.letterSpacing: 1.2
                    elide: Text.ElideRight
                    width: parent.width
                  }
                }
              }

              // ---------- Output ----------
              AudioSeparator {}

              Column {
                width: parent.width
                spacing: 6

                Item {
                  width: parent.width
                  implicitHeight: Math.max(outputHeader.implicitHeight, outputPercent.implicitHeight)
                  height: implicitHeight

                  AudioSectionHeader {
                    id: outputHeader
                    text: "Output"
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                  }

                  Text {
                    id: outputPercent
                    textFormat: Text.PlainText
                    text: Math.round((outputSlider.dragging ? outputSlider.liveValue : content.outputVolume) * 100) + "%"
                    color: Qt.darker(Theme.barColor, 1.4)
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.barFontSizeSmall
                    font.bold: true
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: content.outputMuted ? 0.5 : 1.0
                  }
                }

                Item {
                  width: parent.width
                  height: outputSlider.implicitHeight + 12

                  AudioSlider {
                    id: outputSlider
                    anchors.fill: parent
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    minimum: 0
                    maximum: 1
                    step: 0.05
                    value: content.outputVolume
                    opacity: content.outputMuted ? 0.5 : 1.0
                    enabled: content.hasOutput

                    onMoved: function(v) { content.setOutputVolume(v) }
                    onRightClicked: content.toggleOutputMute()
                  }
                }

                Repeater {
                  model: content.displaySinks

                  DeviceRow {
                    required property var modelData
                    readonly property var node: content.nodeFor(modelData)

                    width: panelColumn.width
                    visible: !!node
                    glyph: AudioModel.sinkGlyph(node)
                    label: AudioModel.nodeLabel(node)
                    active: !!node && !!content.sink && content.sink.id === node.id
                    onClicked: content.setDefaultSink(node)
                  }
                }
              }

              // ---------- Input ----------
              AudioSeparator {
                visible: content.displaySources.length > 0 || !!content.source
              }

              Column {
                width: parent.width
                spacing: 6
                visible: content.displaySources.length > 0 || !!content.source

                Item {
                  width: parent.width
                  implicitHeight: Math.max(inputHeader.implicitHeight, inputPercent.implicitHeight)
                  height: implicitHeight

                  AudioSectionHeader {
                    id: inputHeader
                    text: "Input"
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                  }

                  Text {
                    id: inputPercent
                    textFormat: Text.PlainText
                    text: Math.round((inputSlider.dragging ? inputSlider.liveValue : content.inputVolume) * 100) + "%"
                    color: Qt.darker(Theme.barColor, 1.4)
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.barFontSizeSmall
                    font.bold: true
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: content.inputMuted ? 0.5 : 1.0
                  }
                }

                Item {
                  visible: !!content.source
                  width: parent.width
                  height: inputControls.implicitHeight + 12

                  Column {
                    id: inputControls
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    spacing: 5

                    AudioSlider {
                      id: inputSlider
                      width: parent.width
                      minimum: 0
                      maximum: 1
                      step: 0.05
                      value: content.inputVolume
                      opacity: content.inputMuted ? 0.5 : 1.0
                      enabled: content.hasInput

                      onMoved: function(v) { content.setInputVolume(v) }
                      onRightClicked: content.toggleInputMute()
                    }

                    Rectangle {
                      width: parent.width
                      height: 5
                      color: Qt.rgba(Theme.barColor.r, Theme.barColor.g, Theme.barColor.b, 0.18)
                      opacity: content.inputMuted ? 0.35 : 1.0

                      Rectangle {
                        height: parent.height
                        width: parent.width * Math.max(0, Math.min(1, inputPeakMonitor.peak))
                        color: Theme.barColor
                        Behavior on width { NumberAnimation { duration: 70 } }
                      }
                    }
                  }
                }

                Repeater {
                  model: content.displaySources

                  DeviceRow {
                    required property var modelData
                    readonly property var node: content.nodeFor(modelData)

                    width: panelColumn.width
                    visible: !!node
                    glyph: AudioModel.sourceGlyph(node)
                    label: AudioModel.nodeLabel(node)
                    active: !!node && !!content.source && content.source.id === node.id
                    onClicked: content.setDefaultSource(node)
                  }
                }
              }

              AudioSeparator {
                visible: content.displayStreams.length > 0
              }

              Column {
                width: parent.width
                spacing: 10
                visible: content.displayStreams.length > 0

                AudioSectionHeader {
                  text: "Applications"
                }

                Repeater {
                  model: content.displayStreams

                  Rectangle {
                    id: streamRow
                    required property var modelData
                    readonly property var node: content.nodeFor(modelData)
                    readonly property real streamVolume: node && node.audio ? node.audio.volume : 0
                    readonly property bool streamMuted: node && node.audio ? node.audio.muted : false
                    readonly property bool isActive: !!node && content.streamIsPlaying(node)

                    width: panelColumn.width
                    visible: !!node
                    implicitHeight: streamColumn.implicitHeight + 16
                    radius: Theme.radiusInner
                    color: isActive
                      ? Qt.rgba(Theme.barColor.r, Theme.barColor.g, Theme.barColor.b, 0.14)
                      : (streamHover.hovered
                        ? Qt.rgba(Theme.barColor.r, Theme.barColor.g, Theme.barColor.b, 0.08)
                        : "transparent")

                    HoverHandler { id: streamHover }

                    Column {
                      id: streamColumn
                      anchors.left: parent.left
                      anchors.right: parent.right
                      anchors.verticalCenter: parent.verticalCenter
                      anchors.leftMargin: 6
                      anchors.rightMargin: 6
                      spacing: 2

                      Row {
                        width: parent.width
                        spacing: 8

                        Text {
                          id: streamMuteIcon
                          textFormat: Text.PlainText
                          text: streamRow.streamMuted ? "󰝟" : "󰕾"
                          color: Theme.barColor
                          font.family: Theme.fontFamily
                          font.pixelSize: Theme.fontSize
                          width: 22
                          horizontalAlignment: Text.AlignHCenter
                          anchors.verticalCenter: parent.verticalCenter
                          opacity: streamRow.streamMuted ? 0.5 : 1.0

                          MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                              if (streamRow.node && streamRow.node.audio)
                                streamRow.node.audio.muted = !streamRow.node.audio.muted
                            }
                          }
                        }

                        Text {
                          textFormat: Text.PlainText
                          text: AudioModel.streamLabel(streamRow.node, content.mprisPlayers, content.audioStreams)
                          color: Theme.barColor
                          font.family: Theme.fontFamily
                          font.pixelSize: Theme.fontSizeSmall
                          font.bold: streamRow.isActive
                          elide: Text.ElideRight
                          width: parent.width - streamMuteIcon.width - streamPct.width - 16
                          anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                          id: streamPct
                          textFormat: Text.PlainText
                          text: Math.round(streamRow.streamVolume * 100) + "%"
                          color: Qt.darker(Theme.barColor, 1.5)
                          font.family: Theme.fontFamily
                          font.pixelSize: Theme.barFontSizeSmall
                          font.bold: true
                          width: 36
                          horizontalAlignment: Text.AlignRight
                          anchors.verticalCenter: parent.verticalCenter
                          opacity: streamRow.streamMuted ? 0.5 : 1.0
                        }
                      }

                      AudioSlider {
                        width: parent.width
                        minimum: 0
                        maximum: 1.5
                        step: 0.05
                        value: streamRow.streamVolume
                        opacity: streamRow.streamMuted ? 0.5 : 1.0

                        onMoved: function(v) {
                          if (streamRow.node && streamRow.node.audio) streamRow.node.audio.volume = v
                        }
                        onRightClicked: {
                          if (streamRow.node && streamRow.node.audio)
                            streamRow.node.audio.muted = !streamRow.node.audio.muted
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
