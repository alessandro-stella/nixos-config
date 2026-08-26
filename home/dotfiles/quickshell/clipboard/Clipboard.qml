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

  title: "Clipboard History"
  searchPlaceholder: "Type to search clipboard..."
  resultsText: resultsList.count > 0 ? resultsList.count + " match" + (resultsList.count !== 1 ? "es" : "") + " found" : ""
  maxIndex: Math.max(0, resultsList.count - 1)

  property var historyItems: []

  // Load cliphist data
  onOpened: {
    fetchHistory()
  }

  onEnterPressed: {
    if (root.selectedIndex >= 0 && root.selectedIndex < filteredHistory.values.length) {
      const entry = filteredHistory.values[root.selectedIndex]
      if (entry) root.pasteEntry(entry)
    }
  }

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

  Process {
    id: pasteProcess
  }

  function pasteEntry(rawEntry) {
    if (!rawEntry) return

    const match = rawEntry.match(/^(\d+)/)
    if (!match) return
    const id = match[1]

    StateManager.closeAllWidgets()

    pasteProcess.command = [
      "sh",
      "-c",
      "printf '%s' " + id + " | cliphist decode | wl-copy && sleep 0.15 && wtype -M ctrl v -m ctrl"
    ]
    pasteProcess.running = true
  }

  ScriptModel {
    id: filteredHistory
    values: {
      const all = root.historyItems || []
      const q = root.searchText.trim().toLowerCase()
      
      if (q === "") return all

      return all.filter(item => {
        const content = item.replace(/^\d+\s+/, "")
        return content.toLowerCase().includes(q)
      })
    }
  }

  ListView {
    id: resultsList
    anchors.fill: parent
    model: filteredHistory
    clip: true
    spacing: 4
    boundsBehavior: Flickable.StopAtBounds
    currentIndex: root.selectedIndex

    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

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

        Text {
          text: ""
          color: root.selectedIndex === delegateRoot.index ? Theme.accent2 : Theme.colMuted
          font.pixelSize: Theme.fontSizeSmall
          font.family: Theme.fontFamily
          Layout.alignment: Qt.AlignVCenter
        }

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
