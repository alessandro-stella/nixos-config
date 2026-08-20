import Quickshell.Hyprland
import QtQuick
import "../"

Item {
  id: root

  property int fontSize: Theme.fontSize
  property string fontFamily: "monospace"
  property color textColor: Theme.accent1

  implicitWidth: iconText.implicitWidth
  implicitHeight: iconText.implicitHeight

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onClicked: function() {
      Hyprland.dispatch('hl.dsp.global("quickshell:toggleLauncher")')
    }
  }

  Text {
    id: iconText
    anchors.centerIn: parent

    color: root.textColor
    font.pixelSize: root.fontSize
    font.family: root.fontFamily
    font.bold: true
    text: ""

    transformOrigin: Item.Center
    rotation: mouseArea.containsMouse ? 360 : 0

    Behavior on rotation {
      NumberAnimation {
        duration: Theme.slowAnimation
        easing.type: Easing.OutCubic
      }
    }
  }
}
