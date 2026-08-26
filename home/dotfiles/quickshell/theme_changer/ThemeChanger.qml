import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"

GenericModal {
  id: root

  preferredWidth: 1000

  required property int monitorId
  required property var modelData

  screen: modelData
  shortcutName: "toggleThemeChanger"

  title: "Theme Changer"
  searchPlaceholder: "Search wallpaper"

  property var wallpaperItems: []
  property int carouselIndex: 0

  // Dimensioni tessere
  property real tileWidth: 180
  property real selectedTileWidth: 500
  property real tileHeight: 320

  resultsText:
    filteredWallpapers.values.length > 0
      ? filteredWallpapers.values.length +
        " wallpaper" +
        (filteredWallpapers.values.length !== 1 ? "s" : "") +
        " found"
      : ""

  maxIndex:
    Math.max(
      0,
      filteredWallpapers.values.length - 1
    )

  onOpened: {
    fetchWallpapers()
  }

  onSearchTextChanged: {
    root.carouselIndex = 0
    Qt.callLater(() => {
      if (filteredWallpapers.values.length > 0) {
        carousel.positionViewAtIndex(filteredWallpapers.baseCount, ListView.Center)
      }
    })
  }

  onEnterPressed: {
    const baseCount = filteredWallpapers.baseCount
    if (baseCount > 0) {
      const realIndex = ((root.carouselIndex % baseCount) + baseCount) % baseCount
      const entry = filteredWallpapers.baseValues[realIndex]
      if (entry)
        root.applyWallpaper(entry)
    }
  }

  Process {
    id: wpListProcess

    command: [
      "sh",
      "-c",
      "find ~/Pictures/wallpapers -maxdepth 1 -type f"
    ]

    stdout: SplitParser {
      onRead: data => {
        if (data && data.trim().length > 0) {
          root.wallpaperItems.push(data.trim())
        }
      }
    }

    onExited: {
      root.wallpaperItems = root.wallpaperItems.slice()
      if (filteredWallpapers.baseCount > 0) {
        root.carouselIndex = filteredWallpapers.baseCount // Partiamo dal blocco centrale
        Qt.callLater(() => {
          carousel.positionViewAtIndex(root.carouselIndex, ListView.Center)
        })
      }
    }
  }

  function fetchWallpapers() {
    root.wallpaperItems = []
    if (wpListProcess.running)
      wpListProcess.kill()
    wpListProcess.running = true
  }

  function applyWallpaper(path) {
    if (!path) return
    console.log("Changing wallpaper to " + path)
    StateManager.closeAllWidgets()
  }

  function selectIndex(index) {
    const baseCount = filteredWallpapers.baseCount
    if (baseCount === 0) return

    root.carouselIndex = index
    carousel.positionViewAtIndex(index, ListView.Center)

    // Controllo invisibile per il loop infinito (se usciamo dal blocco centrale)
    Qt.callLater(() => {
      if (root.carouselIndex < baseCount) {
        root.carouselIndex += baseCount
        carousel.positionViewAtIndex(root.carouselIndex, ListView.Center)
      } else if (root.carouselIndex >= baseCount * 2) {
        root.carouselIndex -= baseCount
        carousel.positionViewAtIndex(root.carouselIndex, ListView.Center)
      }
    })
  }

  // ScriptModel con triplicazione dei dati per il loop infinito fluido
  ScriptModel {
    id: filteredWallpapers

    property var baseValues: {
      const all = root.wallpaperItems || []
      const q = root.searchText.trim().toLowerCase()

      if (q === "")
        return all

      return all.filter(item => {
        const fileName = item.split("/").pop()
        return fileName.toLowerCase().includes(q)
      })
    }

    property int baseCount: baseValues.length

    values: {
      if (baseCount === 0) return []
      // Triplichiamo l'array: [Blocco Precedente, Blocco Centrale, Blocco Successivo]
      return baseValues.concat(baseValues, baseValues)
    }
  }

  Item {
    anchors.fill: parent

    Item {
      id: carouselContainer
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: bottomBar.top
      anchors.bottomMargin: 10

      ListView {
        id: carousel

        anchors.fill: parent
        orientation: ListView.Horizontal
        model: filteredWallpapers
        clip: true
        spacing: 12
        focus: true
        boundsBehavior: Flickable.StopAtBounds

        // Buffer di cache enorme per precaricare le immagini ed evitare qualsiasi lag durante lo scorrimento
        cacheBuffer: width * 4

        // Forza l'elemento attivo bloccato esattamente al centro dello schermo
        preferredHighlightBegin: width / 2 - root.selectedTileWidth / 2
        preferredHighlightEnd: width / 2 + root.selectedTileWidth / 2
        highlightRangeMode: ListView.StrictlyEnforceRange

        delegate: Item {
          id: delegateRoot

          required property string modelData
          required property int index

          property bool active: index === root.carouselIndex

          width: active ? root.selectedTileWidth : root.tileWidth
          height: carouselContainer.height

          Behavior on width {
            NumberAnimation { duration: Theme.fastAnimation; easing.type: Easing.OutCubic }
          }

          Image {
            id: img
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            source: "file://" + delegateRoot.modelData
            transform: Shear { xFactor: -0.25 }

            opacity: delegateRoot.active ? 1.0 : 0.55

            Behavior on opacity {
              NumberAnimation { duration: Theme.fastAnimation }
            }
          }

          Rectangle {
            id: borderRect
            z: 10
            anchors.fill: parent
            visible: delegateRoot.active
            color: "transparent"
            border.width: Theme.borderWidth
            border.color: Theme.accent2
            transform: Shear { xFactor: -0.25 }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              root.selectIndex(delegateRoot.index)
              const baseCount = filteredWallpapers.baseCount
              if (baseCount > 0) {
                const realIndex = ((delegateRoot.index % baseCount) + baseCount) % baseCount
                root.applyWallpaper(filteredWallpapers.baseValues[realIndex])
              }
            }
          }
        }

        WheelHandler {
          acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
          onWheel: event => {
            if (event.angleDelta.y > 0) {
              root.selectIndex(root.carouselIndex - 1)
            } else if (event.angleDelta.y < 0) {
              root.selectIndex(root.carouselIndex + 1)
            }
            event.accepted = true
          }
        }
      }

      // Freccia Sinistra
      Rectangle {
        id: leftButton
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        width: 42
        height: 64
        radius: Theme.radiusInner
        color: Theme.colBg
        opacity: filteredWallpapers.baseCount > 0 ? 0.85 : 0.25

        Behavior on opacity { NumberAnimation { duration: Theme.fastAnimation } }

        Text {
          anchors.centerIn: parent
          text: "‹"
          color: Theme.colFg
          font.pixelSize: 42
          font.family: Theme.fontFamily
        }

        MouseArea {
          anchors.fill: parent
          enabled: filteredWallpapers.baseCount > 0
          cursorShape: Qt.PointingHandCursor
          onClicked: root.selectIndex(root.carouselIndex - 1)
        }
      }

      // Freccia Destra
      Rectangle {
        id: rightButton
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        width: 42
        height: 64
        radius: Theme.radiusInner
        color: Theme.colBg
        opacity: filteredWallpapers.baseCount > 0 ? 0.85 : 0.25

        Behavior on opacity { NumberAnimation { duration: Theme.fastAnimation } }

        Text {
          anchors.centerIn: parent
          text: "›"
          color: Theme.colFg
          font.pixelSize: 42
          font.family: Theme.fontFamily
        }

        MouseArea {
          anchors.fill: parent
          enabled: filteredWallpapers.baseCount > 0
          cursorShape: Qt.PointingHandCursor
          onClicked: root.selectIndex(root.carouselIndex + 1)
        }
      }
    }

    // Barra in basso (Nome + Preview)
    RowLayout {
      id: bottomBar
      anchors.bottom: parent.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      height: 45
      spacing: 15

      Text {
        Layout.fillWidth: true
        Layout.leftMargin: 15
        text: {
          const baseCount = filteredWallpapers.baseCount
          if (baseCount > 0 && root.carouselIndex >= 0) {
            const realIndex = ((root.carouselIndex % baseCount) + baseCount) % baseCount
            const path = filteredWallpapers.baseValues[realIndex]
            return path ? path.split("/").pop().replace(/\.[^/.]+$/, "") : "No selection"
          }
          return "No selection"
        }
        color: Theme.colFg
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
        font.bold: true
        elide: Text.ElideRight
      }

      Rectangle {
        Layout.preferredWidth: 100
        Layout.preferredHeight: 36
        Layout.rightMargin: 15
        radius: Theme.radiusInner
        color: Theme.colBg
        border.width: Theme.borderWidth
        border.color: Theme.accent2

        Text {
          anchors.centerIn: parent
          text: "Preview"
          color: Theme.colFg
          font.pixelSize: Theme.fontSizeSmall
          font.family: Theme.fontFamily
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            const baseCount = filteredWallpapers.baseCount
            if (baseCount > 0 && root.carouselIndex >= 0) {
              const realIndex = ((root.carouselIndex % baseCount) + baseCount) % baseCount
              const path = filteredWallpapers.baseValues[realIndex]
              console.log("Previewing wallpaper: " + path)
            }
          }
        }
      }
    }
  }

  Text {
    anchors.centerIn: parent
    text:
      root.wallpaperItems.length === 0
        ? "No wallpapers found"
        : "No matches found"
    color: Theme.colMuted
    font.pixelSize: Theme.fontSize
    font.family: Theme.fontFamily
    visible: filteredWallpapers.baseCount === 0
  }
}
