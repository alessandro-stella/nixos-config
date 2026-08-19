import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../generic_modal/"

GenericModal {
  id: root

  ipcTarget: "clipboard"
  shortcutName: "toggleClipboard"

  property int selectedIndex: 0
  property var historyItems: []

  // Carica gli elementi da cliphist all'apertura
  onOpened: {
    searchInput.text = ""
    root.selectedIndex = 0
    fetchHistory()
    searchInput.forceActiveFocus()
  }

  // Processo per recuperare la cronologia
  Process {
    id: cliphistListProcess
    command: ["cliphist", "list"]
    stdout: SplitParser {
      onRead: data => {
        if (data && data.trim().length > 0) {
          root.historyItems.push(data)
        }
      }
    }
    onExited: (exitCode, exitStatus) => {
      root.historyItems = root.historyItems.slice()
    }
  }

  function fetchHistory() {
    root.historyItems = []
    if (cliphistListProcess.running) {
      cliphistListProcess.kill()
    }
    cliphistListProcess.running = true
  }

  // Processo per decodificare, copiare e incollare
  Process {
    id: pasteProcess
  }

  function pasteEntry(rawEntry) {
    if (!rawEntry) return

    // 1. Estraiamo solo l'ID numerico di cliphist (es. "5830")
    const match = rawEntry.match(/^(\d+)/)
    if (!match) return
    const id = match[1]

    root.close()

    // 2. Passiamo l'ID pulito a cliphist decode
    pasteProcess.command = [
      "sh",
      "-c",
      "printf '%s' " + id + " | cliphist decode | wl-copy && sleep 0.15 && wtype -M ctrl v -m ctrl"
    ]
    pasteProcess.running = true
  }

  // Modello per filtrare la cronologia
  ScriptModel {
    id: filteredHistory
    values: {
      const all = root.historyItems || []
      const q = searchInput.text.trim().toLowerCase()
      
      if (q === "") return all

      return all.filter(item => {
        // Rimuove l'ID numerico iniziale di cliphist prima di filtrare
        const content = item.replace(/^\d+\s+/, "")
        return content.toLowerCase().includes(q)
      })
    }
  }

  FocusScope {
    anchors.fill: parent
    focus: true

    ColumnLayout {
      anchors.fill: parent
      spacing: 12

      // Header
      RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
          text: ""
          color: Theme.accent2
          font.pixelSize: Theme.fontSize
          font.family: Theme.fontFamily
        }

        Text {
          text: "Clipboard History"
          color: Theme.accent2
          font.pixelSize: Theme.fontSize
          font.family: Theme.fontFamily
          font.bold: true
        }
      }

      // Barra di ricerca
      Rectangle {
        Layout.fillWidth: true
        height: 42
        radius: Theme.radiusInner
        color: "#24283b"
        border.color: searchInput.activeFocus ? Theme.accent2 : Theme.colMuted
        border.width: Theme.borderWidth

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 12
          anchors.rightMargin: 12
          spacing: 10

          Text {
            text: ""
            color: Theme.colMuted
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontFamily
            Layout.alignment: Qt.AlignVCenter
          }

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

            Text {
              anchors.fill: parent
              text: "Type to search clipboard..."
              color: Theme.colMuted
              font.pixelSize: Theme.fontSize
              font.family: Theme.fontFamily
              visible: !parent.text && !parent.activeFocus
              verticalAlignment: Text.AlignVCenter
            }

            onTextChanged: root.selectedIndex = 0

            Keys.onEscapePressed: root.close()

            Keys.onPressed: event => {
              if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                event.accepted = true
                root.selectedIndex = Math.min(root.selectedIndex + 1, resultsList.count - 1)
                resultsList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
              } else if (event.key === Qt.Key_Up) {
                event.accepted = true
                root.selectedIndex = Math.max(root.selectedIndex - 1, 0)
                resultsList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
              } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                event.accepted = true
                if (root.selectedIndex >= 0 && root.selectedIndex < filteredHistory.values.length) {
                  const entry = filteredHistory.values[root.selectedIndex]
                  if (entry) root.pasteEntry(entry)
                }
              }
            }
          }
        }
      }

      // Conteggio risultati
      Text {
        text: resultsList.count + " item" + (resultsList.count !== 1 ? "s" : "")
        color: Theme.colMuted
        font.pixelSize: 11
        font.family: Theme.fontFamily
      }

      // Lista degli elementi copiati
      ListView {
        id: resultsList
        Layout.fillWidth: true
        Layout.fillHeight: true
        model: filteredHistory
        clip: true
        spacing: 4
        boundsBehavior: Flickable.StopAtBounds
        currentIndex: root.selectedIndex

        highlightMoveDuration: 60
        highlightResizeDuration: 60

        highlight: Rectangle {
          radius: 8
          color: "#2f3549"
          visible: root.selectedIndex >= 0

          Rectangle {
            width: 3
            height: 24
            radius: 2
            color: Theme.accent2
            anchors.left: parent.left
            anchors.leftMargin: 3
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        delegate: Rectangle {
          id: delegateRoot
          required property var modelData
          required property int index

          readonly property string displayText: {
            if (!modelData) return ""
            return modelData.replace(/^\d+\s+/, "")
          }

          width: resultsList.width
          height: 38
          radius: 8
          color: "transparent"

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12

            // Icona indicatrice
            Text {
              text: ""
              color: root.selectedIndex === delegateRoot.index ? Theme.accent2 : Theme.colMuted
              font.pixelSize: Theme.fontSizeSmall
              font.family: Theme.fontFamily
              Layout.alignment: Qt.AlignVCenter
            }

            // Testo della voce copiata
            Text {
              text: delegateRoot.displayText
              color: root.selectedIndex === delegateRoot.index ? Theme.accent2 : Theme.colFg
              font.pixelSize: Theme.fontSizeSmall
              font.family: Theme.fontFamily
              font.bold: root.selectedIndex === delegateRoot.index
              elide: Text.ElideRight
              Layout.fillWidth: true
              Layout.alignment: Qt.AlignVCenter
            }
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: root.selectedIndex = delegateRoot.index
            onClicked: root.pasteEntry(delegateRoot.modelData)
          }
        }

        // Messaggio vuoto
        Text {
          anchors.centerIn: parent
          text: root.historyItems.length === 0 ? "Clipboard is empty" : "No matches found"
          color: Theme.colMuted
          font.pixelSize: Theme.fontSize
          font.family: Theme.fontFamily
          visible: resultsList.count === 0
        }
      }
    }
  }
}
