import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import "../.."

Rectangle {
  id: root

  required property var device

  property bool isActive: false

  signal setAsActive()

  // Tracciamo ogni singolo dispositivo mostrato nella lista
  PwObjectTracker {
    objects: root.device ? [root.device] : []
  }

  implicitHeight: contentLayout.implicitHeight + 20
  color: isActive ? Theme.widgetLightBackground : "transparent"
  radius: Theme.radiusInner
  border.color: isActive ? Theme.accent2 : "transparent"
  border.width: isActive ? 1 : 0

  opacity: (Pipewire.ready && root.device && root.device.ready) ? 1 : 0
  Behavior on opacity {
    NumberAnimation { duration: Theme.fastAnimation }
  }

  Behavior on color {
    ColorAnimation { duration: Theme.fastAnimation }
  }

  readonly property real deviceVolume: {
    if (!Pipewire.ready || !root.device || !root.device.ready || !root.device.audio) return 0;
    return root.device.audio.volume ?? 0;
  }

  readonly property bool deviceMuted: (root.device && root.device.ready && root.device.audio) ? root.device.audio.muted : false
  readonly property string deviceName: root.device?.description || root.device?.nickname || root.device?.name || "Unknown"

  ColumnLayout {
    id: contentLayout
    anchors.fill: parent
    anchors.margins: 10
    spacing: 8

    RowLayout {
      Layout.fillWidth: true
      spacing: 8

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        Text {
          text: root.deviceName
          font.bold: true
          font.pixelSize: Theme.fontSizeSmall
          color: Theme.barColor
          font.family: Theme.fontFamily
          Layout.fillWidth: true
          elide: Text.ElideRight
        }
      }

      Rectangle {
        visible: root.isActive
        implicitWidth: 6
        implicitHeight: 6
        radius: 3
        color: root.deviceMuted ? Theme.colRed : Theme.colGreen
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 3

      RowLayout {
        Layout.fillWidth: true
        Text {
          text: "Volume"
          font.pixelSize: 11
          color: Theme.barDarkColor
          font.family: Theme.fontFamily
        }
        Item { Layout.fillWidth: true }
        Text {
          text: Math.round(root.deviceVolume * 100) + "%"
          font.pixelSize: 11
          color: Theme.barColor
          font.bold: true
          font.family: Theme.fontFamily
        }
      }

      Rectangle {
        Layout.fillWidth: true
        implicitHeight: 8
        radius: 4
        color: Theme.widgetDarkBackground

        Rectangle {
          anchors.left: parent.left
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          width: root.deviceMuted ? parent.width : (parent.width * Math.max(0, Math.min(1, root.deviceVolume)))
          color: root.deviceMuted ? Theme.colRed : Theme.colGreen
          radius: 4

          Behavior on width {
            NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
          }
          Behavior on color {
            ColorAnimation { duration: 100 }
          }
        }

        MouseArea {
          anchors.fill: parent
          preventStealing: true
          
          // Disabilita l'interazione e cambia l'icona del cursore se mutato
          enabled: !root.deviceMuted
          cursorShape: root.deviceMuted ? Qt.ForbiddenCursor : Qt.PointingHandCursor

          function applyVolume(mousePos) {
            if (root.device && root.device.ready && root.device.audio) {
              root.device.audio.volume = Math.max(0, Math.min(1, (mousePos.x / parent.width)));
            }
          }

          onPositionChanged: (mouse) => {
            if (pressed) applyVolume(mouse);
          }

          onPressed: (mouse) => {
            applyVolume(mouse);
          }
        }
      }
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: 6

      Rectangle {
        Layout.fillWidth: true
        implicitHeight: 28
        radius: Theme.radiusInner
        // Rosso pieno se mutato, accent2 trasparente altrimenti
        color: root.deviceMuted ? Theme.colRed : Qt.rgba(Theme.accent2.r, Theme.accent2.g, Theme.accent2.b, 0.2)
        border.color: root.deviceMuted ? Theme.colRed : Theme.accent2
        border.width: 1

        Text {
          anchors.centerIn: parent
          text: root.deviceMuted ? "󰖁 Unmute" : "󰕾 Mute"
          font.pixelSize: 11
          font.bold: true
          // Scritta scura per farla leggere sul rosso acceso
          color: root.deviceMuted ? Theme.widgetDarkBackground : Theme.barColor
          font.family: Theme.fontFamily
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (root.device && root.device.ready && root.device.audio) {
              root.device.audio.muted = !root.device.audio.muted;
            }
          }

          onEntered: parent.color = root.deviceMuted ? Qt.lighter(Theme.colRed, 1.1) : Qt.rgba(Theme.accent2.r, Theme.accent2.g, Theme.accent2.b, 0.35)
          onExited: parent.color = root.deviceMuted ? Theme.colRed : Qt.rgba(Theme.accent2.r, Theme.accent2.g, Theme.accent2.b, 0.2)
        }
      }

      Rectangle {
        Layout.fillWidth: true
        implicitHeight: 28
        radius: Theme.radiusInner
        color: root.isActive ? Qt.rgba(Theme.accent1.r, Theme.accent1.g, Theme.accent1.b, 0.2) : "transparent"
        border.color: Theme.accent1
        border.width: 1
        opacity: root.isActive ? 0.7 : 1

        Text {
          anchors.centerIn: parent
          text: root.isActive ? "✓ Active" : "Set"
          font.pixelSize: 11
          font.bold: true
          color: root.isActive ? Theme.accent2 : Theme.barColor
          font.family: Theme.fontFamily
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: root.isActive ? Qt.ArrowCursor : Qt.PointingHandCursor
          enabled: !root.isActive
          onClicked: root.setAsActive()

          onEntered: if (!root.isActive) parent.color = Qt.rgba(Theme.accent2.r, Theme.accent2.g, Theme.accent2.b, 0.25)
          onExited: if (!root.isActive) parent.color = "transparent"
        }
      }
    }
  }
}
