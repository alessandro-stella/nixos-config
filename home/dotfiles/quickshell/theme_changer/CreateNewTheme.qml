import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"

GenericModal {
  id: root

  preferredWidth: 800

  required property int monitorId
  required property var modelData

  screen: modelData
  shortcutName: "toggleCreateNewTheme"

  title: "Create New Theme"

  Item {
    anchors.fill: parent

    ColumnLayout {
      anchors.centerIn: parent
      spacing: 20

      Text {
        text: "Configurazione per la creazione di un nuovo tema."
        color: Theme.colFg
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
      }

      // Tasto per tornare a ThemeChanger
      Rectangle {
        Layout.preferredWidth: 240
        Layout.preferredHeight: 45
        radius: Theme.radiusInner
        color: browseMouseArea.containsMouse ? Theme.accent1 : Theme.colBg
        border.width: Theme.borderWidth
        border.color: Theme.accent1

        Behavior on color {
          ColorAnimation { duration: Theme.fastAnimation }
        }

        Text {
          anchors.centerIn: parent
          text: "Sfoglia i temi esistenti"
          color: browseMouseArea.containsMouse ? Theme.colBg : Theme.accent1
          font.pixelSize: Theme.fontSizeSmall
          font.family: Theme.fontFamily
        }

        MouseArea {
          id: browseMouseArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            StateManager.closeAllWidgets()

            for (const widget of StateManager.activeWidgets) {
              if (widget.shortcutName === "toggleThemeChanger") {
                widget.open()
              }
            }
          }
        }
      }
    }
  }
}
