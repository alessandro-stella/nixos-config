import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "../"

RowLayout {
  id: root
  property int fontSize: Theme.barFontSize ?? 12

  spacing: 0
  Layout.fillHeight: true

  Repeater {
    model: {
      const list = [...Hyprland.workspaces.values]
      return list.sort((a, b) => a.id - b.id)
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

      Layout.fillHeight: true
      Layout.preferredWidth: height
      radius: 6

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

      MouseArea {
        id: wsMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
          Hyprland.dispatch("hl.dsp.focus({ workspace = " + modelData.id + " })")
        }
      }
    }
  }
}
