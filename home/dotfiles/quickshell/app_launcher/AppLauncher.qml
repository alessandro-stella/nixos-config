import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../generic_modal/"

GenericModal {
  id: root

  ipcTarget: "launcher"
  shortcutName: "toggleLauncher"

  property int selectedIndex: 0

  onOpened: {
    searchInput.text = ""
    root.selectedIndex = 0
    searchInput.forceActiveFocus()
  }

  function launchApp(entry) {
    if (!entry) return
    entry.execute()
    root.close()
  }

  ScriptModel {
    id: filteredApps
    objectProp: "id"
    values: {
    const all = [...DesktopEntries.applications.values]
    const q = searchInput.text.trim().toLowerCase()
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

  // Contenuto effettivo iniettato nel GenericModal
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
          text: ""
          color: Theme.accent2
          font.pixelSize: Theme.fontSize
          font.family: Theme.fontFamily
        }

        Text {
          text: "Applications"
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
              text: "Type to search..."
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
                if (root.selectedIndex >= 0 && root.selectedIndex < filteredApps.values.length) {
                  const entry = filteredApps.values[root.selectedIndex]
                  if (entry) root.launchApp(entry)
                }
              }
            }
          }
        }
      }

      // Conteggio risultati
      Text {
        text: resultsList.count + " application" + (resultsList.count !== 1 ? "s" : "")
        color: Theme.colMuted
        font.pixelSize: Theme.fontSizeSmall
        font.family: Theme.fontFamily
      }

      // Lista delle applicazioni
      ListView {
        id: resultsList
        Layout.fillWidth: true
        Layout.fillHeight: true
        model: filteredApps
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

          width: resultsList.width
          height: 40
          radius: 8
          color: "transparent"

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12

            // Icona
            Item {
              width: 24
              height: 24
              Layout.alignment: Qt.AlignVCenter

              Image {
                id: appIcon
                anchors.fill: parent
                source: (delegateRoot.modelData.icon && delegateRoot.modelData.icon !== "") ? "image://icon/" + delegateRoot.modelData.icon : ""
                smooth: true
                mipmap: true
                visible: status === Image.Ready
              }

              // Fallback testuale/icona
              Text {
                anchors.centerIn: parent
                visible: appIcon.status !== Image.Ready
                text: delegateRoot.modelData.name ? delegateRoot.modelData.name.charAt(0).toUpperCase() : ""
                color: root.selectedIndex === delegateRoot.index ? Theme.accent2 : Theme.colMuted
                font.pixelSize: Theme.fontSize
                font.family: Theme.fontFamily
                font.bold: true
              }
            }

            // Nome + Descrizione
            ColumnLayout {
              Layout.fillWidth: true
              Layout.alignment: Qt.AlignVCenter
              spacing: 1

              Text {
                text: delegateRoot.modelData.name ?? ""
                color: root.selectedIndex === delegateRoot.index ? Theme.accent2 : Theme.colFg
                font.pixelSize: Theme.fontSizeSmall
                font.family: Theme.fontFamily
                font.bold: root.selectedIndex === delegateRoot.index
                elide: Text.ElideRight
                Layout.fillWidth: true
              }

              Text {
                text: delegateRoot.modelData.genericName ?? delegateRoot.modelData.comment ?? ""
                color: Theme.colMuted
                font.pixelSize: Theme.fontSizeSmall
                font.family: Theme.fontFamily
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: text !== ""
              }
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

        // Messaggio lista vuota
        Text {
          anchors.centerIn: parent
          text: "No applications found"
          color: Theme.colMuted
          font.pixelSize: Theme.fontSize
          font.family: Theme.fontFamily
          visible: resultsList.count === 0 && searchInput.text !== ""
        }
      }
    }
  }
}
