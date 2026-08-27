import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import "../.."

Scope {
  id: smallPopupRoot

  required property real scrollStep
  required property Item targetItem
  required property PanelWindow parentWindow
  required property var defaultSink

  property bool _isLoaded: false
  property bool _isVisible: false
  property var hidePopupTimer: null

  signal aboutToShow()

  TextMetrics {
    id: mutedMetrics
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSizeSmall
    font.bold: true
    text: "Muted"
  }

  PwObjectTracker {
    objects: smallPopupRoot.defaultSink ? [smallPopupRoot.defaultSink] : []
  }

  function show() {
    if (!_isVisible) {
      _isVisible = true
      if (!_isLoaded) {
        _isLoaded = true
      }
      aboutToShow()
      if (popupLoader.item) {
        popupLoader.item.show()
      }
    }
  }

  function hide() {
    if (_isVisible) {
      _isVisible = false
      if (popupLoader.item) {
        popupLoader.item.hide()
      }
    }
  }

  readonly property real currentVolume: {
    if (!Pipewire.ready || !defaultSink || !defaultSink.ready || !defaultSink.audio) return 0;
    return Math.max(0, Math.min(1, defaultSink.audio.volume));
  }

  readonly property bool currentMuted: {
    if (!Pipewire.ready || !defaultSink || !defaultSink.ready || !defaultSink.audio) return false;
    return defaultSink.audio.muted;
  }

  Loader {
    id: popupLoader
    active: smallPopupRoot._isLoaded
    sourceComponent: popupInnerComponent
  }

  Component {
    id: popupInnerComponent

    Scope {
      id: innerScope

      function show() {
        popup.visible = true
      }

      function hide() {
        popup.visible = false
      }

      PopupWindow {
        id: popup

        anchor.window: smallPopupRoot.parentWindow
        anchor.item: smallPopupRoot.targetItem
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.margins.top: Theme.barHeight + Math.round(Theme.outerSpacing / 2) - Math.round(Theme.borderWidth / 2)

        visible: false
        color: "transparent"

        implicitWidth: mutedMetrics.width + 24
        implicitHeight: 220

        Rectangle {
          id: card

          anchors.fill: parent
          color: Theme.widgetDarkBackground
          radius: Theme.radiusOuter
          border.color: Theme.accent1
          border.width: Theme.borderWidth

          clip: true
          transformOrigin: Item.Top

          opacity: (Pipewire.ready && popup.visible) ? 1 : 0

          Behavior on opacity {
            NumberAnimation {
              duration: Theme.fastAnimation
              easing.type: Easing.OutCubic
            }
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton

            onWheel: (wheel) => {
              if (Pipewire.ready && smallPopupRoot.defaultSink && smallPopupRoot.defaultSink.ready && smallPopupRoot.defaultSink.audio) {
                let step = root.scrollStep;
                    
                let isTrackpad = (wheel.phase !== 0); 
                let isScrollUp = isTrackpad ? (wheel.angleDelta.y < 0) : (wheel.angleDelta.y > 0);

                if (isScrollUp) {
                  smallPopupRoot.defaultSink.audio.volume = Math.min(1.0, smallPopupRoot.defaultSink.audio.volume + step);
                } else {
                  smallPopupRoot.defaultSink.audio.volume = Math.max(0.0, smallPopupRoot.defaultSink.audio.volume - step);
                }
              }
            }

            onEntered: {
              if (smallPopupRoot.hidePopupTimer) {
                smallPopupRoot.hidePopupTimer.stop()
              }
            }

            onExited: {
              if (smallPopupRoot.hidePopupTimer) {
                smallPopupRoot.hidePopupTimer.start()
              }
            }
          }

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            Item {
              Layout.alignment: Qt.AlignHCenter
              Layout.fillHeight: true
              Layout.preferredWidth: 16

              Rectangle {
                anchors.fill: parent
                color: smallPopupRoot.currentMuted ? Theme.colRed : Theme.widgetLightBackground
                radius: 8

                Rectangle {
                  anchors.bottom: parent.bottom
                  anchors.left: parent.left
                  anchors.right: parent.right
                  height: parent.height * smallPopupRoot.currentVolume
                  color: smallPopupRoot.currentMuted ? Theme.colRed : Theme.colGreen
                  radius: 8

                  Behavior on height {
                    NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
                  }
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: smallPopupRoot.currentMuted ? Qt.ForbiddenCursor : Qt.PointingHandCursor
                  preventStealing: true
                  enabled: !smallPopupRoot.currentMuted

                  function applyVolume(mousePos) {
                    if (Pipewire.ready && smallPopupRoot.defaultSink && smallPopupRoot.defaultSink.ready && smallPopupRoot.defaultSink.audio) {
                      smallPopupRoot.defaultSink.audio.volume = Math.max(0, Math.min(1, ((parent.height - mousePos.y) / parent.height)));
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

            Text {
              id: percentageLabel
              Layout.alignment: Qt.AlignHCenter
              text: smallPopupRoot.currentMuted ? "Muted" : Math.round(smallPopupRoot.currentVolume * 100) + "%"
              font.pixelSize: Theme.fontSizeSmall
              font.bold: true
              color: smallPopupRoot.currentMuted ? Theme.colRed : Theme.barColor
              font.family: Theme.fontFamily
            }
          }
        }
      }
    }
  }
}
