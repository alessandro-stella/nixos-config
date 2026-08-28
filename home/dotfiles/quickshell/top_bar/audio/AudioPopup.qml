import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import Quickshell
import QtQuick.Controls
import Quickshell.Services.Pipewire
import "../.."

Scope {
  id: popupScope

  required property Item targetItem
  required property PanelWindow parentWindow

  property bool isOpen: false
  property bool _isLoaded: false

  function toggle() {
    if (!isOpen) {
      _isLoaded = true
      StateManager.requestOpen(popupScope)
    } else {
      StateManager.requestClose(popupScope)
    }
  }

  readonly property real dynamicWidth: 440

  Loader {
    id: popupLoader
    active: popupScope._isLoaded
    sourceComponent: popupContentComponent

    onLoaded: {
      if (item) {
        item.isOpen = popupScope.isOpen
      }
    }
  }

  Connections {
    target: popupScope
    function onIsOpenChanged() {
      if (popupLoader.item && popupLoader.item.isOpen !== popupScope.isOpen) {
        popupLoader.item.isOpen = popupScope.isOpen
      }
    }
  }

  Component {
    id: popupContentComponent

    GenericPopup {
      id: genericPopup
      
      parentWindow: popupScope.parentWindow
      targetItem: popupScope.targetItem
      popupWidth: popupScope.dynamicWidth

      onIsOpenChanged: {
        if (popupScope.isOpen !== isOpen) {
          popupScope.isOpen = isOpen
        }
      }

      contentComponent: Component {
        ColumnLayout {
          id: contentRoot
          spacing: 12
          
          opacity: Pipewire.ready ? 1 : 0
          Behavior on opacity {
            NumberAnimation { duration: Theme.slowAnimation }
          }

          // Header
          Item {
            Layout.fillWidth: true
            height: titleText.height

            RowLayout {
              anchors.fill: parent
              spacing: 8

              Text {
                id: titleText
                text: "Audio Devices"
                font.bold: true
                font.pixelSize: Theme.fontSize
                color: Theme.barColor
                font.family: Theme.fontFamily
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
              }

              Rectangle {
                width: 28
                height: 28
                radius: 6
                color: settingsMouse.containsMouse
                  ? Theme.widgetLightBackground
                  : "transparent"

                Text {
                  text: "󰒓"
                  font.pixelSize: Theme.fontSize
                  color: Theme.barColor
                  font.family: Theme.fontFamily
                  anchors.centerIn: parent 
                } 

                MouseArea {
                  id: settingsMouse 
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    Quickshell.execDetached(["pavucontrol"])
                  }
                }
              }
            }
          }

          // Scrollable area for all devices
          ScrollView {
            id: scrollView
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min((Screen.height / 2) - 50, listContainer.implicitHeight)
            clip: true

            contentWidth: availableWidth

            ColumnLayout {
              id: listContainer
              width: scrollView.availableWidth
              spacing: 12

              // Output devices
              ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                  text: "Output"
                  font.bold: true
                  font.pixelSize: Theme.fontSizeSmall
                  color: Theme.barDarkColor
                  font.family: Theme.fontFamily
                }

                Repeater {
                  id: outputRepeater
                  model: ScriptModel {
                    values: Pipewire.ready ? Pipewire.nodes.values.filter(node => {
                      if (!node.isSink || node.isStream || !node.audio) return false;
                      return true;
                    }) : []
                  }

                  delegate: Component {
                    AudioDeviceItem {
                      required property var modelData

                      Layout.fillWidth: true
                      device: modelData
                      isActive: modelData === Pipewire.defaultAudioSink
                      
                      onSetAsActive: {
                        if (device && device.ready) {
                          Pipewire.preferredDefaultAudioSink = device
                        }
                      }
                    }
                  }
                }

                Text {
                  visible: outputRepeater.count === 0
                  text: "No output device found"
                  font.pixelSize: 12
                  color: Theme.barMutedColor
                  font.family: Theme.fontFamily
                  font.italic: true
                }
              }

              // Divider
              Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.widgetLightBackground
              }

              // Input devices
              ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                  text: "Input"
                  font.bold: true
                  font.pixelSize: Theme.fontSizeSmall
                  color: Theme.barDarkColor
                  font.family: Theme.fontFamily
                }

                Repeater {
                  id: inputRepeater
                  model: ScriptModel {
                    values: Pipewire.ready ? Pipewire.nodes.values.filter(node => {
                      if (!node.audio || node.isSink || node.isStream) return false;
                      
                      const name = (node.description || node.name || "").toLowerCase();
                      if (name.includes("dummy") || name.includes("freewheel") || name.includes("midi") || name.includes("bridge")) {
                        return false;
                      }
                      return true;
                    }) : []
                  }

                  delegate: Component {
                    AudioDeviceItem {
                      required property var modelData

                      Layout.fillWidth: true
                      device: modelData
                      isActive: modelData === Pipewire.defaultAudioSource
                      
                      onSetAsActive: {
                        if (device && device.ready) {
                          Pipewire.preferredDefaultAudioSource = device
                        }
                      }
                    }
                  }
                }

                Text {
                  visible: inputRepeater.count === 0
                  text: "No input device found"
                  font.pixelSize: 12
                  color: Theme.barMutedColor
                  font.family: Theme.fontFamily
                  font.italic: true
                }
              }
            }
          }
        }
      }
    }
  }
}
