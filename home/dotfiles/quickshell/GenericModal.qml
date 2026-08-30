import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"

ModalBackdrop {
  id: root

  // If > 0 override automatic width calculation
  property real preferredWidth: 0

  readonly property real widgetWidthRatio: 0.30
  readonly property int widgetMinWidth: 440
  readonly property int widgetMaxWidth: 640

  readonly property int widgetMinHeight: 380
  readonly property int widgetMaxHeight: 520
  readonly property int widgetDefaultHeight: 480

  property alias boxWidth: launcherBox.width
  property alias boxHeight: launcherBox.height

  property string title: ""
  property string searchPlaceholder: "Type to search..."
  property alias searchText: searchInput.text
  property string resultsText: ""
  property int selectedIndex: 0
  property int maxIndex: 0

  // Signal for child class
  signal enterPressed()

  default property alias content: innerContainer.data

  onOpened: {
    searchInput.text = ""
    root.selectedIndex = 0
    searchInput.forceActiveFocus()
  }

  // Main container
  Rectangle {
    id: launcherBox

    anchors.centerIn: parent

    width: root.preferredWidth > 0
      ? root.preferredWidth
      : root.screen
        ? Math.max(
            root.widgetMinWidth,
            Math.min(
              Math.round(root.screen.width * root.widgetWidthRatio),
              root.widgetMaxWidth
            )
          )
        : root.widgetMaxWidth

    height: Math.min(
      root.widgetDefaultHeight,
      root.widgetMaxHeight
    )

    radius: Theme.radiusOuter
    color: Theme.colBg
    border.color: Theme.accent1
    border.width: Theme.borderWidth

    // Prevent clicks from reaching the backdrop.
    MouseArea {
      anchors.fill: parent
      onClicked: {}
    }

    // Content
    FocusScope {
      anchors.fill: parent
      anchors.margins: 16
      focus: true

      ColumnLayout {
        anchors.fill: parent
        spacing: 12

        // Header
        Text {
          text: root.title
          color: Theme.colFg
          font.pixelSize: Theme.fontSize
          font.family: Theme.fontFamily
          font.bold: true
          visible: text !== ""
        }

        // Search bar
        Rectangle {
          Layout.fillWidth: true
          height: 42

          radius: Theme.radiusInner
          color: "#24283b"

          border.color: searchInput.activeFocus
            ? Theme.accent2
            : Theme.colMuted

          border.width: Theme.borderWidth

          RowLayout {
            anchors.fill: parent

            anchors.leftMargin: 12
            anchors.rightMargin: 12

            spacing: 10

            // Search icon
            Text {
              text: ""
              color: Theme.colMuted
              font.pixelSize: Theme.fontSize
              font.family: Theme.fontFamily

              Layout.alignment: Qt.AlignVCenter
            }

            // Search input
            TextInput {
              id: searchInput

              Layout.fillWidth: true
              Layout.alignment: Qt.AlignVCenter

              color: Theme.colFg

              font.pixelSize: Theme.fontSize
              font.family: Theme.fontFamily

              clip: true
              focus: true
              selectByMouse: true

              // Placeholder
              Text {
                anchors.fill: parent

                text: root.searchPlaceholder

                color: Theme.colMuted

                font.pixelSize: Theme.fontSize
                font.family: Theme.fontFamily

                visible: !parent.text 

                verticalAlignment: Text.AlignVCenter
              }

              onTextChanged: {
                root.selectedIndex = 0
              }

              Keys.onEscapePressed: {
                StateManager.closeAllWidgets()
              }

              Keys.onPressed: event => {
                if (
                  event.key === Qt.Key_Down ||
                  event.key === Qt.Key_Tab
                ) {
                  event.accepted = true

                  root.selectedIndex = Math.min(
                    root.selectedIndex + 1,
                    root.maxIndex
                  )
                }

                else if (event.key === Qt.Key_Up) {
                  event.accepted = true

                  root.selectedIndex = Math.max(
                    root.selectedIndex - 1,
                    0
                  )
                }

                else if (
                  event.key === Qt.Key_Return ||
                  event.key === Qt.Key_Enter
                ) {
                  event.accepted = true

                  root.enterPressed()
                }
              }
            }
          }
        }


        // Result count
        Text {
          text: root.resultsText

          color: Theme.colMuted

          font.pixelSize: Theme.fontSizeSmall
          font.family: Theme.fontFamily

          visible: text !== ""
        }

        // Content
        Item {
          id: innerContainer

          Layout.fillWidth: true
          Layout.fillHeight: true
        }
      }
    }
  }
}
