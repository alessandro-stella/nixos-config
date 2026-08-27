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

  function toggle() {
    isOpen = !isOpen
    if (isOpen) {
      StateManager.requestOpen(popupScope)
    } else {
      StateManager.requestClose(popupScope)
    }
  }

  readonly property real dynamicWidth: 440

  // Istanziamo direttamente il GenericPopup incorporando la logica del contenuto
  GenericPopup {
    id: genericPopup
    
    parentWindow: popupScope.parentWindow
    targetItem: popupScope.targetItem
    popupWidth: popupScope.dynamicWidth
    
    isOpen: popupScope.isOpen

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

        // Header con Titolo e Pulsante Impostazioni[cite: 2]
        RowLayout {
          Layout.fillWidth: true
          spacing: 8

          Text {
            text: "Audio Devices"
            font.bold: true
            font.pixelSize: Theme.fontSize
            color: Theme.barColor
            font.family: Theme.fontFamily
            Layout.fillWidth: true
          }

          Text {
            text: "󰒓"
            font.pixelSize: Theme.fontSize
            color: Theme.barDarkColor
            font.family: Theme.fontFamily

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                Quickshell.execDetached(["pavucontrol"])
              }
              onEntered: parent.color = Theme.colCyan
              onExited: parent.color = Theme.barDarkColor
            }
          }
        }

        // Area scorribile per i device[cite: 2]
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

            // Output devices[cite: 2]
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

            // Divider[cite: 2]
            Rectangle {
              Layout.fillWidth: true
              Layout.preferredHeight: 1
              color: Theme.widgetLightBackground
            }

            // Input devices[cite: 2]
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
