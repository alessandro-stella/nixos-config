import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.impl
import "../"

ModalBackdrop {
  id: root

  required property int monitorId
  required property var modelData

  screen: modelData
  shortcutName: "toggleLogoutMenu"

  property real widthScale: 0.7
  property real heightScale: 0.35

  property var actions: [
    { icon: "lock", action: "swaylock -K", text: "Lock" },
    { icon: "logout", action: "hyprctl dispatch 'hl.dsp.exit()'", text: "Logout" },
    { icon: "suspend", action: "systemctl suspend", text: "Suspend" },
    { icon: "shutdown", action: "systemctl poweroff", text: "Shutdown" },
    { icon: "reboot", action: "systemctl reboot", text: "Reboot" }
  ]

  FocusScope {
    anchors.fill: parent
    focus: true

    Rectangle {
      id: mainContainer

      anchors.centerIn: parent

      implicitWidth: Math.round(parent.width * root.widthScale)
      implicitHeight: Math.round(parent.height * root.heightScale)

      width: implicitWidth
      height: implicitHeight

      color: Theme.colBg
      radius: Theme.radiusOuter

      RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.borderWidth
        spacing: 0

        Repeater {
          model: root.actions

          delegate: Item {
            id: delegateItem

            Layout.fillWidth: true
            Layout.fillHeight: true

            property bool isHovered: buttonArea.containsMouse
            property bool isFirst: index === 0
            property bool isLast: index === (root.actions.length - 1)

            Process {
              id: actionProcess

              command: ["sh", "-c", modelData.action]
            }

            // Wait for render before executing command
            Timer {
              id: actionTimer

              interval: Theme.fastAnimation
              repeat: false

              onTriggered: {
                actionProcess.running = true
              }
            }

            Rectangle {
              id: bgRect

              anchors.centerIn: parent

              width: parent.width
              height: isHovered ? parent.height + 50 : parent.height

              property color currentBg: isHovered
                ? Theme.accent1
                : Theme.colBg

              property color currentFg: isHovered
                ? Theme.colBg
                : Theme.accent1

              color: currentBg
              z: isHovered ? 10 : 1

              border.width: isHovered ? Theme.borderWidth : 0
              border.color: Theme.accent1

              radius: isHovered
                ? Theme.radiusOuter
                : 0

              Behavior on height {
                NumberAnimation {
                  duration: 200
                  easing.type: Easing.OutCubic
                }
              }

              Behavior on radius {
                NumberAnimation {
                  duration: 200
                  easing.type: Easing.OutCubic
                }
              }

              Behavior on color {
                ColorAnimation {
                  duration: Theme.slowAnimation
                  easing.type: Easing.OutCubic
                }
              }

              ColumnLayout {
                anchors.centerIn: parent
                width: parent.width

                IconImage {
                  Layout.alignment: Qt.AlignHCenter

                  source: "./icons/" + modelData.icon + ".svg"

                  width: 64
                  height: 64

                  color: bgRect.currentFg

                  Behavior on color {
                    ColorAnimation {
                      duration: 200
                      easing.type: Easing.OutCubic
                    }
                  }
                }

                Text {
                  Layout.alignment: Qt.AlignHCenter

                  text: modelData.text

                  font.pixelSize: Theme.fontSize + 5

                  color: bgRect.currentFg

                  Behavior on color {
                    ColorAnimation {
                      duration: Theme.slowAnimation
                      easing.type: Easing.OutCubic
                    }
                  }
                }
              }
            }

            MouseArea {
              id: buttonArea

              anchors.fill: parent

              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor

              onClicked: {
                StateManager.closeAllWidgets()
                actionTimer.start()
              }
            }
          }
        }
      }
    }
  }
}
