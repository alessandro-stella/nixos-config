import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "../"

RowLayout {
  id: root

  property bool showOnlyCurrentMonitor: false
  property int currentMonitorId: -1

  property var parentWindow: null

  property bool previewEnabled: true
  property int previewDelay: 600          
  property int previewWidth: 320          
  property int previewPadding: 4          
  property bool previewUsableArea: true   
  property bool previewLive: false       
  property bool previewKeepOpen: false 

  property int fontSize: Theme.barFontSize
  spacing: 0
  Layout.fillHeight: true

  Repeater {
    model: {
      const list = [...Hyprland.workspaces.values]
      const sorted = list.sort((a, b) => a.id - b.id)

      if (root.showOnlyCurrentMonitor && root.currentMonitorId !== null) {
        return sorted.filter(ws => {
          const wsMonitorId = ws.monitorId ?? ws.monitor?.id ?? ws.monitor
          return wsMonitorId !== null && wsMonitorId === root.currentMonitorId
        })
      }

      return sorted
    }

    delegate: Rectangle {
      id: wsButton
      required property var modelData

      readonly property bool isFocused: Hyprland.focusedWorkspace ? (Hyprland.focusedWorkspace.id === modelData.id) : false
      readonly property bool isUrgent: {
        if (!Hyprland.toplevels) return false;
        return Hyprland.toplevels.values.some(client =>
          client.workspace &&
          client.workspace.id === modelData.id &&
          (client.urgent === true || client.demandsAttention === true)
        );
      }
      readonly property bool isHovered: wsMouse.containsMouse

      readonly property var wsToplevels: {
        if (!Hyprland.toplevels) return []
        const list = Hyprland.toplevels.values.filter(t =>
          t && t.workspace && t.workspace.id === modelData.id)
        return list.sort((a, b) => {
          const fa = a.lastIpcObject && a.lastIpcObject.floating ? 1 : 0
          const fb = b.lastIpcObject && b.lastIpcObject.floating ? 1 : 0
          return fa - fb
        })
      }

      // ---- Monitor geometry ----
      readonly property var mon: modelData.monitor
      readonly property real monScale: {
        if (!mon) return 1
        const s = mon.lastIpcObject && mon.lastIpcObject.scale ? mon.lastIpcObject.scale : mon.scale
        return s && s > 0 ? s : 1
      }
      readonly property real monX: mon ? (mon.x !== undefined ? mon.x : (mon.lastIpcObject ? mon.lastIpcObject.x : 0)) : 0
      readonly property real monY: mon ? (mon.y !== undefined ? mon.y : (mon.lastIpcObject ? mon.lastIpcObject.y : 0)) : 0
      readonly property real monLogicalW: mon && mon.width > 0 ? mon.width / monScale : 1920
      readonly property real monLogicalH: mon && mon.height > 0 ? mon.height / monScale : 1080

      // Reserved space
      readonly property var reserved: mon && mon.lastIpcObject && mon.lastIpcObject.reserved
        ? mon.lastIpcObject.reserved : [0, 0, 0, 0]
      readonly property real resL: root.previewUsableArea ? (reserved[0] || 0) : 0
      readonly property real resT: root.previewUsableArea ? (reserved[1] || 0) : 0
      readonly property real resR: root.previewUsableArea ? (reserved[2] || 0) : 0
      readonly property real resB: root.previewUsableArea ? (reserved[3] || 0) : 0

      // Monitor region shown by the preview 
      readonly property real regionX: monX + resL
      readonly property real regionY: monY + resT
      readonly property real regionW: Math.max(1, monLogicalW - resL - resR)
      readonly property real regionH: Math.max(1, monLogicalH - resT - resB)

      property bool previewVisible: false

      Layout.fillHeight: true
      Layout.preferredWidth: height
      radius: 6
      antialiasing: true
      color: {
        if (isHovered) return Theme.barWorkspaceHover
        return "transparent"
      }
      Behavior on color {
        ColorAnimation { duration: 150; easing.type: Easing.InOutQuad }
      }

      // Urgent top
      Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Theme.barColor
        visible: wsButton.isUrgent
      }

      // Urgent bottom
      Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Theme.barColor
        visible: wsButton.isUrgent
      }

      // Workspace button
      Text {
        id: wsLabel
        anchors.centerIn: parent
        text: modelData.name || modelData.id
        font.pixelSize: root.fontSize
        font.family: Theme.fontFamily
        font.bold: true
        color: {
          if (wsButton.isUrgent || wsButton.isFocused) return Theme.barColor
          if (wsButton.isHovered) return Theme.barDarkColor
          return Theme.barMutedColor
        }
        Behavior on color {
          ColorAnimation { duration: 150; easing.type: Easing.InOutQuad }
        }
      }

      // Delay before showing preview
      Timer {
        id: hoverDelay
        interval: root.previewDelay
        repeat: false
        onTriggered: {
          if (!wsMouse.containsMouse || wsButton.wsToplevels.length === 0) return
          Hyprland.refreshToplevels() 
          wsButton.previewVisible = true
        }
      }

      MouseArea {
        id: wsMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onEntered: {
          if (root.previewEnabled && wsButton.wsToplevels.length > 0)
            hoverDelay.restart()
        }
        onExited: {
          hoverDelay.stop()
          if (!root.previewKeepOpen) wsButton.previewVisible = false
        }
        onClicked: function(mouse) {
          if (mouse.button === Qt.RightButton) {
            hoverDelay.stop()
            wsButton.previewVisible = false
            return
          }
          hoverDelay.stop()
          if (!root.previewKeepOpen) wsButton.previewVisible = false
          Hyprland.dispatch("hl.dsp.focus({ workspace = " + modelData.id + " })")
        }
      }

      Loader {
        active: wsButton.previewVisible

        sourceComponent: PopupWindow {
          id: previewPopup

          anchor.window: root.parentWindow ?? wsButton.QsWindow.window
          anchor.item: wsButton
          anchor.edges: Edges.Bottom
          anchor.gravity: Edges.Bottom

          visible: true
          color: "transparent"

          readonly property real inset: root.previewPadding + Theme.borderWidth
          readonly property real innerW: root.previewWidth - 2 * inset
          readonly property real scaleK: innerW / wsButton.regionW
          readonly property real innerH: Math.round(wsButton.regionH * scaleK)
          readonly property real cardHeight: innerH + 2 * inset

          implicitWidth: root.previewWidth
          implicitHeight: cardHeight + Math.round(Theme.outerSpacing / 2)

          Rectangle {
            id: card

            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.previewWidth
            height: previewPopup.cardHeight

            color: Theme.widgetDarkBackground
            radius: Theme.radiusOuter
            antialiasing: true
            border.color: Theme.accent1
            border.width: Theme.borderWidth
            clip: true

            transformOrigin: Item.Top
            property bool shown: false
            opacity: shown ? 1 : 0
            scale: shown ? 1 : 0.94
            Component.onCompleted: shown = true

            Behavior on opacity {
              NumberAnimation { duration: Theme.fastAnimation; easing.type: Easing.OutCubic }
            }
            Behavior on scale {
              NumberAnimation { duration: Theme.fastAnimation; easing.type: Easing.OutCubic }
            }

            // Internal preview area
            Item {
              id: canvas
              x: previewPopup.inset
              y: previewPopup.inset
              width: previewPopup.innerW
              height: previewPopup.innerH
              clip: true

              Repeater {
                model: wsButton.wsToplevels

                delegate: Rectangle {
                  id: winBox
                  required property var modelData

                  readonly property var at: modelData.lastIpcObject && modelData.lastIpcObject.at ? modelData.lastIpcObject.at : [0, 0]
                  readonly property var sz: modelData.lastIpcObject && modelData.lastIpcObject.size ? modelData.lastIpcObject.size : [0, 0]

                  x: Math.round((at[0] - wsButton.regionX) * previewPopup.scaleK)
                  y: Math.round((at[1] - wsButton.regionY) * previewPopup.scaleK)
                  width: Math.max(1, Math.round(sz[0] * previewPopup.scaleK))
                  height: Math.max(1, Math.round(sz[1] * previewPopup.scaleK))
                  visible: sz[0] > 0 && sz[1] > 0

                  color: Theme.widgetLightBackground
                  radius: 3
                  antialiasing: true
                  clip: true

                  // Window placeholder while the image loads 
                  Text {
                    anchors.centerIn: parent
                    visible: !capture.hasContent
                    text: winBox.modelData.lastIpcObject && winBox.modelData.lastIpcObject.class
                      ? winBox.modelData.lastIpcObject.class : ""
                    color: Theme.colMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.barFontSizeSmall
                    elide: Text.ElideRight
                    width: parent.width - 8
                    horizontalAlignment: Text.AlignHCenter
                  }

                  ScreencopyView {
                    id: capture
                    anchors.fill: parent
                    captureSource: winBox.modelData.wayland
                    live: root.previewLive
                    paintCursor: false

                    smooth: true
                    layer.enabled: true
                    layer.smooth: true
                    layer.mipmap: true
                  }

                  // Thin border around windows
                  Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    radius: 3
                    antialiasing: true
                    border.color: Theme.barDarkColor
                    border.width: 1
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
