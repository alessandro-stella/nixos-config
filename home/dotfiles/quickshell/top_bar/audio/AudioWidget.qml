import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick.Controls.impl
import "../.."

Item {
  id: root

  required property PanelWindow parentWindow

  implicitWidth: referenceIcon.width
  implicitHeight: parent.height

  readonly property real scrollStep: 0.01

  readonly property var defaultSink: {
    if (!Pipewire.ready) return null;
    if (Pipewire.defaultAudioSink) return Pipewire.defaultAudioSink;
    const sinks = Pipewire.nodes.values.filter(n => n.isSink && !n.isStream);
    return sinks.length > 0 ? sinks[0] : null;
  }

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

  readonly property string audioIconText: {
    if (root.isMuted) return "";

    const vol = root.volumePercent;

    if (vol === 0) return "";
    if (vol <= 50) return "";
    return "";
  }

  readonly property color activeColor: Theme.barColor

    // Icon container
    Item {
      id: iconContainer
      anchors.centerIn: parent
      Layout.preferredWidth: referenceIcon.implicitWidth > 0 ? referenceIcon.implicitWidth : 18
      Layout.preferredHeight: Theme.barHeight 
      Layout.alignment: Qt.AlignVCenter

      // Invisible text to force max width 
      Text {
        id: referenceIcon
        text: ""
        anchors.centerIn: parent
        font.pixelSize: Theme.barFontSize
        visible: false
      }
      
      // Actual icon
      Text {
        id: iconText
        text: root.audioIconText
        anchors.centerIn: parent
        font.pixelSize: Theme.barFontSize
        color: Theme.barColor
      }
    }

  AudioPopupSmall {
    id: smallPopup
    parentWindow: root.parentWindow
    targetItem: root
    defaultSink: root.defaultSink
    hidePopupTimer: hideSmallPopupTimer
    scrollStep: root.scrollStep
  }

  AudioPopup {
    id: audioPopup
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
        let step = root.scrollStep;
        
        let isTrackpad = (wheel.phase !== 0); 
        let isScrollUp = isTrackpad ? (wheel.angleDelta.y < 0) : (wheel.angleDelta.y > 0);

        if (isScrollUp) {
          root.defaultSink.audio.volume = Math.min(1.0, root.defaultSink.audio.volume + step);
        } else {
          root.defaultSink.audio.volume = Math.max(0.0, root.defaultSink.audio.volume - step);
        }
      }
    }

    onEntered: {
      if (audioPopup.isOpen) return;
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
        audioPopup.toggle()
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
