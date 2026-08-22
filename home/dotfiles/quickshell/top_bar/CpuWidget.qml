import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "../"

Item {
  id: root

  // Proprietà obbligatorie passate dalla barra
  required property var parentWindow

  // Proprietà opzionali per lo stile
  property int fontSize: 12
  property string fontFamily: "monospace"

  Layout.preferredHeight: parentWindow.height
  Layout.preferredWidth: cpuText.implicitWidth + 24

  Text {
    id: cpuText
    text: "CPU: 157%"
    color: Theme.colYellow
    font.pixelSize: root.fontSize
    font.family: root.fontFamily
    font.bold: true
    anchors.centerIn: parent
  }

  MouseArea {
    id: cpuMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
  }

  // Tooltip
  PopupWindow {
    id: cpuTooltip
    visible: cpuMouse.containsMouse

    anchor.window: root.parentWindow
    anchor.rect.x: root.x
    anchor.rect.y: 0
    anchor.rect.width: root.width
    anchor.rect.height: root.parentWindow.height
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom

    implicitWidth: 180
    implicitHeight: 50
    color: "transparent"

    Rectangle {
      anchors.fill: parent
      anchors.margins: 4
      radius: 6
      color: Theme.colBg
      border.color: Theme.colYellow
      border.width: 1

      ColumnLayout {
        anchors.centerIn: parent
        spacing: 2

        Text {
          text: "Utilizzo Processore"
          color: Theme.colYellow
          font.pixelSize: 11
          font.family: root.fontFamily
          font.bold: true
          Layout.alignment: Qt.AlignHCenter
        }

        Text {
          text: "Carico: 500%"
          color: "#cdd6f4"
          font.pixelSize: 10
          font.family: root.fontFamily
          Layout.alignment: Qt.AlignHCenter
        }
      }
    }
  }
}
