import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"

GenericModal {
  id: root

required property int monitorId
  required property var modelData

  screen: modelData
  shortcutName: "toggleClipboard"

  property int selectedIndex: 0
  property var historyItems: []

  // Load cliphist data
  onOpened: {
    searchInput.text = ""
    root.selectedIndex = 0
    fetchHistory()
    searchInput.forceActiveFocus()
  }

  // Get history
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

  // Handle decode, copy and paste
  Process {
    id: pasteProcess
  }

  function pasteEntry(rawEntry) {
    if (!rawEntry) return

    // Get cliphist numeric id
    const match = rawEntry.match(/^(\d+)/)
    if (!match) return
    const id = match[1]

    StateManager.closeAllWidgets()

    // Pass id to cliphist decode
    pasteProcess.command = [
      "sh",
      "-c",
      "printf '%s' " + id + " | cliphist decode | wl-copy && sleep 0.15 && wtype -M ctrl v -m ctrl"
    ]
    pasteProcess.running = true
  }

  // Filter history
  ScriptModel {
    id: filteredHistory
    values: {
      const all = root.historyItems || []
      const q = searchInput.text.trim().toLowerCase()
      
      if (q === "") return all

      return all.filter(item => {
        const content = item.replace(/^\d+\s+/, "")
        return content.toLowerCase().includes(q)
      })
    }
  }

  // GenericModal content
  FocusScope {
    anchors.fill: parent
    focus: true

    ColumnLayout {
      anchors.fill: parent
      spacing: 12

      // Header
      Text {
        text: "Clipboard History"
        color: Theme.accent2
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
        font.bold: true
      }

      // Search bar
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

            Keys.onEscapePressed: StateManager.closeAllWidgets()

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

      // Count results
      Text {
        text: resultsList.count + " match" + (resultsList.count !== 1 ? "es" : "") + " found"
        color: Theme.colMuted
        font.pixelSize: Theme.fontSizeSmall
        font.family: Theme.fontFamily
        visible: resultsList.count > 0
      }

      // Show clipboard history
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

            // Icon
            Text {
              text: ""
              color: root.selectedIndex === delegateRoot.index ? Theme.accent2 : Theme.colMuted
              font.pixelSize: Theme.fontSizeSmall
              font.family: Theme.fontFamily
              Layout.alignment: Qt.AlignVCenter
            }

            // Copied text
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

        // Empty or no match
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
