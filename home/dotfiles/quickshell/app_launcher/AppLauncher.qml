import Quickshell
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
  shortcutName: "toggleLauncher"

  title: "Launch Application"
  searchPlaceholder: "Type to search..."
  resultsText: resultsList.count > 0 ? resultsList.count + " application" + (resultsList.count !== 1 ? "s" : "") + " found" : ""
  maxIndex: Math.max(0, resultsList.count - 1)

  onEnterPressed: {
    if (root.selectedIndex >= 0 && root.selectedIndex < filteredApps.values.length) {
      const entry = filteredApps.values[root.selectedIndex]
      if (entry) root.launchApp(entry)
    }
  }

  function launchApp(entry) {
    if (!entry) return
    entry.execute()
    StateManager.closeAllWidgets()
  }

  ScriptModel {
    id: filteredApps
    objectProp: "id"
    values: {
      const all = [...DesktopEntries.applications.values]
      const q = root.searchText.trim().toLowerCase()
      if (q === "") return all.sort((a, b) => (a.name || "").localeCompare(b.name || ""))

      return all.filter(d =>
        (d.name && d.name.toLowerCase().includes(q))
      ).sort((a, b) => {
        const an = (a.name || "").toLowerCase()
        const bn = (b.name || "").toLowerCase()
        const aStarts = an.startsWith(q)
        const bStarts = bn.startsWith(q)
        if (aStarts && !bStarts) return -1
        if (!aStarts && bStarts) return 1
        return an.localeCompare(bn)
      })
    }
  }

  ListView {
    id: resultsList
    anchors.fill: parent
    model: filteredApps
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

      width: resultsList.width
      height: 40
      radius: 8
      color: "transparent"

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        // Icon
        Item {
          width: 24
          height: 24
          Layout.alignment: Qt.AlignVCenter

          Image {
            id: appIcon
            anchors.fill: parent
            source: delegateRoot.modelData.icon ? Quickshell.iconPath(delegateRoot.modelData.icon, true) : ""
            smooth: true
            mipmap: true
            visible: status === Image.Ready
          }

          // Icon/text fallback
          Rectangle {
            anchors.fill: parent
            visible: appIcon.status !== Image.Ready
            
            color: "transparent" 
            
            border.color: root.selectedIndex === delegateRoot.index ? Theme.accent2 : Theme.colMuted
            border.width: 1
            radius: 4

            Text {
              anchors.centerIn: parent
              text: delegateRoot.modelData.name ? delegateRoot.modelData.name.charAt(0).toUpperCase() : ""
              color: root.selectedIndex === delegateRoot.index ? Theme.accent2 : Theme.colMuted
              font.pixelSize: Theme.fontSize
              font.family: Theme.fontFamily
              font.bold: true
            }
          }
        } 

        // Name
        Text {
          text: delegateRoot.modelData.name ?? ""
          color: root.selectedIndex === delegateRoot.index ? Theme.accent2 : Theme.colFg
          font.pixelSize: Theme.fontSizeSmall
          font.family: Theme.fontFamily
          font.bold: root.selectedIndex === delegateRoot.index
          elide: Text.ElideRight
          Layout.fillWidth: true
        } 
      }

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.selectedIndex = delegateRoot.index
        onClicked: root.launchApp(delegateRoot.modelData)
      }
    }

    // Empty or not found 
    Text {
      anchors.centerIn: parent
      text: "No applications found"
      color: Theme.colMuted
      font.pixelSize: Theme.fontSize
      font.family: Theme.fontFamily
      visible: resultsList.count === 0 && root.searchText !== ""
    }
  }
}
