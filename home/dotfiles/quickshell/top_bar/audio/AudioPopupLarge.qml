import QtQuick
import QtQuick.Window // <-- Aggiunto per leggere Screen.height
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import "../.."

ColumnLayout {
  id: contentRoot
  spacing: 12
  
  // Rimosso Layout.maximumHeight perché inefficace sulla radice

  opacity: Pipewire.ready ? 1 : 0
  Behavior on opacity {
    NumberAnimation { duration: Theme.slowAnimation }
  }

  // Header con Titolo e Pulsante Impostazioni
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

  // Area scorribile per i device
  ScrollView {
    id: scrollView
    Layout.fillWidth: true
    
    // IL SEGRETO: Prende l'altezza implicita della lista, ma si blocca a metà schermo.
    // Sottraggo 50 pixel per fare spazio al testo "Audio Devices" sopra.
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
