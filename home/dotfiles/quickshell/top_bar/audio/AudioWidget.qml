import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import "../.."

Rectangle {
  id: root

  required property PanelWindow parentWindow

  implicitWidth: contentRow.implicitWidth
  implicitHeight: parent.height
  color: "transparent"

  readonly property var defaultSink: {
    if (!Pipewire.ready) return null;
    if (Pipewire.defaultAudioSink) return Pipewire.defaultAudioSink;
    const sinks = Pipewire.nodes.values.filter(n => n.isSink && !n.isStream);
    return sinks.length > 0 ? sinks[0] : null;
  }

  // IL SEGRETO: Tracciamo il nodo per renderlo "bound" e sbloccare i volumi
  PwObjectTracker {
    objects: root.defaultSink ? [root.defaultSink] : []
  }

  opacity: (Pipewire.ready && root.defaultSink && root.defaultSink.ready) ? 1 : 0
  Behavior on opacity {
    NumberAnimation {
      duration: Theme.slowAnimation
      easing.type: Easing.InOutQuad
    }
  }

  readonly property real volumePercent: {
    if (!root.defaultSink || !root.defaultSink.ready || !root.defaultSink.audio) return 0;
    const aud = root.defaultSink.audio;
    const vol = (aud.volumes && aud.volumes.length > 0) ? aud.volumes[0] : (aud.volume ?? 0);
    return Math.max(0, Math.min(1, vol)) * 100;
  }

  readonly property bool isMuted: (root.defaultSink && root.defaultSink.ready && root.defaultSink.audio) ? root.defaultSink.audio.muted : false

  readonly property string audioIcon: {
    if (root.isMuted) return "󰖁";

    const vol = root.volumePercent;

    if (vol === 0) return "󰕿";
    if (vol <= 33) return "󰖀";
    if (vol <= 66) return "󰕾";
    return "";
  }

  readonly property color activeColor: Theme.barColor

  RowLayout {
    id: contentRow
    anchors.centerIn: parent
    spacing: 4

    Text {
      text: root.audioIcon
      font.pixelSize: Theme.barFontSize
      font.family: Theme.fontFamily
      color: root.activeColor
    }

    Text {
      text: Math.round(root.volumePercent) + "%"
      font.pixelSize: Theme.barFontSize
      color: Theme.barColor
      font.family: Theme.fontFamily
    }
  }

  AudioPopupSmall {
    id: smallPopup
    parentWindow: root.parentWindow
    targetItem: root
    defaultSink: root.defaultSink
    hidePopupTimer: hideSmallPopupTimer
  }

  AudioPopup {
    id: largePopup
    parentWindow: root.parentWindow
    targetItem: root
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    onWheel: (wheel) => {
      if (root.defaultSink && root.defaultSink.ready && root.defaultSink.audio) {
        let step = 0.05;
        
        // Se la fase è diversa da 0 (Qt.NoScrollPhase), è quasi certamente un trackpad
        let isTrackpad = (wheel.phase !== 0); 
        
        // Applichiamo la logica invertita solo se stiamo usando il trackpad
        let isScrollUp = isTrackpad ? (wheel.angleDelta.y < 0) : (wheel.angleDelta.y > 0);

        if (isScrollUp) {
          root.defaultSink.audio.volume = Math.min(1.0, root.defaultSink.audio.volume + step);
        } else {
          root.defaultSink.audio.volume = Math.max(0.0, root.defaultSink.audio.volume - step);
        }
      }
    }

    onEntered: {
      if (largePopup.isOpen) return;
      hideSmallPopupTimer.stop()
      smallPopup.show()
    }

    onExited: {
      hideSmallPopupTimer.start()
    }

    onClicked: (mouse) => {
      if (mouse.button === Qt.LeftButton) {
        if (root.defaultSink && root.defaultSink.ready && root.defaultSink.audio) {
          root.defaultSink.audio.muted = !root.defaultSink.audio.muted
        }
      } else if (mouse.button === Qt.RightButton) {
        hideSmallPopupTimer.stop()
        smallPopup.hide()
        largePopup.toggle()
      }
    }
  }

  Timer {
    id: hideSmallPopupTimer
    interval: 500
    running: false
    repeat: false
    onTriggered: smallPopup.hide()
  }
}
