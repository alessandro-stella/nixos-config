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
  searchPlaceholder: "Type to search theme..."

  property var themeItems: []
  property int carouselIndex: 0
  property string currentThemeName: ""
  property bool themeConfirmed: false
  
  // Skip animations during initial load
  property bool skipAnimations: false

  property real tileWidth: 120
  property real selectedTileWidth: 500
  property real tileHeight: 320
  property int imageSourceWidth: 800
  property int imageSourceHeight: 640

  FileView {
    id: currentThemeFile
    path: Quickshell.env("HOME") + "/.config/themes/current_theme/name"
    onLoaded: {
      root.currentThemeName = currentThemeFile.text().trim()
      console.log("Current theme:", root.currentThemeName)
      root.tryCenteringCurrentWallpaper()
    }
  }

  resultsText:
    filteredThemes.baseCount > 0
      ? filteredThemes.baseCount +
        " theme" +
        (filteredThemes.baseCount !== 1 ? "s" : "") +
        " found"
      : ""

  maxIndex:
    Math.max(
      0,
      filteredThemes.values.length - 1
    )

  onOpened: {
    root.themeConfirmed = false
    root.skipAnimations = true
    currentThemeFile.reload()
    fetchThemes()
  }

  onClosed: {
    if (!root.themeConfirmed && root.isFocusedMonitor()) {
      const originalWallpaper = Quickshell.env("HOME") + "/.config/themes/current_theme/wallpaper.png"
      awwwProcess.command = ["awww", "img", "--transition-type", "fade", "--transition-duration", "1.0", "--transition-step", "90", originalWallpaper]
      awwwProcess.running = true
    }
  }

  onSearchTextChanged: {
    Qt.callLater(() => {
      const baseCount = filteredThemes.baseCount
      if (baseCount > 1) {
        const middleRepetition = Math.floor(filteredThemes.repetitions / 2)
        const targetIndex = middleRepetition * baseCount
        
        // Turn off animation during filtering on search bar
        const oldDuration = carousel.highlightMoveDuration
        carousel.highlightMoveDuration = 0
        
        root.carouselIndex = targetIndex
        carousel.currentIndex = targetIndex
        carousel.positionViewAtIndex(targetIndex, ListView.Center)
        
        Qt.callLater(() => {
          carousel.positionViewAtIndex(targetIndex, ListView.Center)
          carousel.highlightMoveDuration = oldDuration
        })
      }
    })
  }

  onEnterPressed: {
    const baseCount = filteredThemes.baseCount
    if (baseCount === 1) {
      const theme = filteredThemes.baseValues[0]
      if (theme) root.changeTheme(theme)
    } else if (baseCount > 1) {
      const realIndex = ((root.carouselIndex % baseCount) + baseCount) % baseCount
      const theme = filteredThemes.baseValues[realIndex]
      if (theme) root.changeTheme(theme)
    }
  }

  Process {
    id: themeListProcess

    command: [
      "sh",
      "-c",
      "find -L " + Quickshell.env("HOME") + "/.config/themes -mindepth 1 -maxdepth 1 -type d -not -name 'current_theme'"
    ]

    stdout: SplitParser {
      onRead: data => {
        if (data && data.trim().length > 0) {
          const themeDir = data.trim()
          const themeName = themeDir.split("/").pop()
          const thumbPath = themeDir + "/thumbnail.png"
          const wallpaperPath = themeDir + "/wallpaper.png"

          const themeObj = {
            name: themeName,
            dir: themeDir,
            thumbnail: thumbPath,
            wallpaper: wallpaperPath
          }

          root.themeItems.push(themeObj)
        }
      }
    }

    onExited: {
      root.themeItems = root.themeItems.slice()
      root.tryCenteringCurrentWallpaper()
    }
  }

  Process {
    id: awwwProcess
    command: ["sh", "-c", ""]
  }

  Process {
    id: applyThemeProcess

    stdout: SplitParser {
      onRead: data => {
        console.log("Applying theme: " + data)
      }
    }

    stderr: SplitParser {
      onRead: data => {
        console.error("Error while changing theme: " + data)
      }
    }
  }

  function changeTheme(theme) {
    if (!theme) return
    root.themeConfirmed = true
    
    console.log("Changing theme to: " + theme.name)

    applyThemeProcess.command = [
      "bash",
      Quickshell.env("HOME") + "/.config/quickshell/theme_changer/scripts/apply_theme.sh",
      theme.name
    ]
    
    applyThemeProcess.running = true

    StateManager.closeAllWidgets()
  }

  function fetchThemes() {
    root.themeItems = []
    if (themeListProcess.running)
      themeListProcess.kill()
    themeListProcess.running = true
  }

  function formatThemeName(rawName) {
    if (!rawName) return ""
    let cleaned = rawName.replace(/[-_]/g, " ").trim()
    return cleaned.charAt(0).toUpperCase() + cleaned.slice(1)
  }

  function tryCenteringCurrentWallpaper() {
    Qt.callLater(() => {
      const baseCount = filteredThemes.baseCount
      if (baseCount <= 1 || root.currentThemeName === "") return

      let targetRealIndex = 0
      for (let i = 0; i < filteredThemes.baseValues.length; i++) {
        const theme = filteredThemes.baseValues[i]
        if (theme.name.toLowerCase() === root.currentThemeName.toLowerCase()) {
          targetRealIndex = i 
          break
        }
      }

      const middleRepetition = Math.floor(filteredThemes.repetitions / 2)
      const finalIndex = (middleRepetition * baseCount) + targetRealIndex
      
      // Turn off animations at start
      const oldDuration = carousel.highlightMoveDuration
      carousel.highlightMoveDuration = 0

      root.carouselIndex = finalIndex
      carousel.currentIndex = finalIndex
      carousel.positionViewAtIndex(finalIndex, ListView.Center)
      
      Qt.callLater(() => {
        carousel.positionViewAtIndex(finalIndex, ListView.Center)
        carousel.highlightMoveDuration = oldDuration
        
        Qt.callLater(() => {
          root.skipAnimations = false
        })
      })
    })
  }

  function selectIndex(index) {
    if (root.skipAnimations) return 

    const baseCount = filteredThemes.baseCount
    if (baseCount <= 1) return

    // 1 = moving right, -1 = moving left
    const dir = index > root.carouselIndex ? 1 : (index < root.carouselIndex ? -1 : 0)
    if (dir === 0) return

    let targetIndex = index
    
    const middleRep = Math.floor(filteredThemes.repetitions / 2)
    const middleStart = middleRep * baseCount
    const middleEnd = middleStart + baseCount

    const needsRecenter = targetIndex < middleStart || targetIndex >= middleEnd

    if (needsRecenter) {
      const currentReal = ((root.carouselIndex % baseCount) + baseCount) % baseCount
      const teleportSource = middleStart + currentReal

      root.skipAnimations = true
      const oldDuration = carousel.highlightMoveDuration
      carousel.highlightMoveDuration = 0
      
      root.carouselIndex = teleportSource
      carousel.currentIndex = teleportSource
      carousel.positionViewAtIndex(teleportSource, ListView.Center)
      
      carousel.highlightMoveDuration = oldDuration
      
      Qt.callLater(() => {
        root.skipAnimations = false
        const finalTarget = teleportSource + dir
        root.carouselIndex = finalTarget
        carousel.currentIndex = finalTarget
      })
      
      return
    }

    root.carouselIndex = targetIndex
    carousel.currentIndex = targetIndex
  }

  ScriptModel {
    id: filteredThemes

    property var baseValues: {
      const all = root.themeItems || []
      const q = root.searchText.trim().toLowerCase()

      if (q === "")
        return all

      return all.filter(theme => {
        return theme.name.toLowerCase().includes(q)
      })
    }

    property int baseCount: baseValues.length
    property int repetitions: {
      if (baseCount === 1) return 1
      if (baseCount <= 3) return 5
      return 3
    } 

    values: {
      if (baseCount <= 1) return baseValues

      let repeated = []
      for (let i = 0; i < repetitions; i++) {
        repeated = repeated.concat(baseValues)
      }
      return repeated
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

      Item {
        anchors.centerIn: parent
        width: root.selectedTileWidth
        height: carouselContainer.height
        visible: filteredThemes.baseCount === 1

        property var modelData: filteredThemes.baseCount === 1 ? filteredThemes.baseValues[0] : null

        Image {
          id: singleImg
          anchors.fill: parent
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
          cache: true
          source: parent.modelData ? "file://" + parent.modelData.thumbnail : ""
          sourceSize.width: root.imageSourceWidth
          sourceSize.height: root.imageSourceHeight
        }

        BusyIndicator {
          anchors.centerIn: parent
          running: singleImg.status === Image.Loading
          visible: running
          z: 5
        }

        Rectangle {
          z: 10
          anchors.fill: parent
          color: "transparent"
          border.width: Theme.borderWidth
          border.color: Theme.accent1
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            const theme = parent.modelData
            if (theme) root.changeTheme(theme)
          }
        }
      }

      ListView {
        id: carousel

        anchors.fill: parent
        orientation: ListView.Horizontal
        model: filteredThemes
        clip: true
        spacing: 12
        focus: true
        boundsBehavior: Flickable.StopAtBounds
        visible: filteredThemes.baseCount > 1

        cacheBuffer: Math.max(width * 3, 3000)

        highlightRangeMode: ListView.StrictlyEnforceRange
        highlightMoveDuration: 220
        highlightMoveVelocity: -1
        preferredHighlightBegin: (width - root.tileWidth) / 2
        preferredHighlightEnd: (width + root.tileWidth) / 2

        onWidthChanged: {
          if (width > 0 && count > 0) {
            Qt.callLater(() => {
              positionViewAtIndex(currentIndex, ListView.Center)
            })
          }
        }

        onCountChanged: {
          if (width > 0 && count > 0) {
            Qt.callLater(() => {
              positionViewAtIndex(currentIndex, ListView.Center)
            })
          }
        }

        delegate: Item {
          id: delegateRoot

          required property var modelData
          required property int index

          property bool active: ListView.isCurrentItem
          
          property int dist: index - carousel.currentIndex
          
          property real shiftX: {
            if (dist === 0) return 0
            const offset = (root.selectedTileWidth - root.tileWidth) / 2
            return dist > 0 ? offset : -offset
          }

          width: root.tileWidth
          height: carouselContainer.height
          z: active ? 1 : 0

          Item {
            id: visualContent
            anchors.centerIn: parent
            
            anchors.horizontalCenterOffset: delegateRoot.shiftX

            Behavior on anchors.horizontalCenterOffset {
              enabled: !root.skipAnimations
              NumberAnimation { duration: 150 }
            }

            width: delegateRoot.active ? root.selectedTileWidth : root.tileWidth
            height: delegateRoot.active ? parent.height : parent.height * 0.85

            Behavior on width {
              enabled: !root.skipAnimations
              NumberAnimation { duration: 150 }
            }

            Behavior on height {
              enabled: !root.skipAnimations
              NumberAnimation { duration: 150 }
            }

            Image {
              id: img
              anchors.fill: parent
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
              cache: true
              
              source: "file://" + delegateRoot.modelData.thumbnail
              sourceSize.width: root.imageSourceWidth
              sourceSize.height: root.imageSourceHeight

              opacity: delegateRoot.active ? 1.0 : 0.55

              Behavior on opacity {
                enabled: !root.skipAnimations
                NumberAnimation { duration: 120 }
              }
            }

            BusyIndicator {
              anchors.centerIn: parent
              running: img.status === Image.Loading
              visible: running
              z: 5
            }

            Rectangle {
              id: borderRect
              z: 10
              anchors.fill: parent
              visible: delegateRoot.active
              color: "transparent"
              border.width: Theme.borderWidth
              border.color: Theme.accent1
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                const baseCount = filteredThemes.baseCount
                if (baseCount > 1) {
                  if (!delegateRoot.active) {
                    root.selectIndex(delegateRoot.index)
                  } else {
                    const realIndex = ((delegateRoot.index % baseCount) + baseCount) % baseCount
                    const theme = filteredThemes.baseValues[realIndex]
                    if (theme) root.changeTheme(theme)
                  }
                }
              }
            }
          }
        }

        WheelHandler {
          acceptedDevices: PointerDevice.Mouse
          onWheel: event => {
            if (filteredThemes.baseCount <= 1 || root.skipAnimations) return
            if (event.angleDelta.y > 0) {
              root.selectIndex(root.carouselIndex - 1)
            } else if (event.angleDelta.y < 0) {
              root.selectIndex(root.carouselIndex + 1)
            }
            event.accepted = true
          }
        }
      }

      Rectangle {
        id: leftButton
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        width: 42
        height: 64
        radius: Theme.radiusInner
        color: Theme.colBg
        opacity: filteredThemes.baseCount > 1 ? 0.85 : 0
        visible: filteredThemes.baseCount > 1

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
          enabled: filteredThemes.baseCount > 1
          cursorShape: Qt.PointingHandCursor
          onClicked: root.selectIndex(root.carouselIndex - 1)
        }
      }

      Rectangle {
        id: rightButton
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        width: 42
        height: 64
        radius: Theme.radiusInner
        color: Theme.colBg
        opacity: filteredThemes.baseCount > 1 ? 0.85 : 0
        visible: filteredThemes.baseCount > 1

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
          enabled: filteredThemes.baseCount > 1
          cursorShape: Qt.PointingHandCursor
          onClicked: root.selectIndex(root.carouselIndex + 1)
        }
      }
    }

    RowLayout {
      id: bottomBar
      anchors.bottom: parent.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      height: 45
      spacing: 15

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: parent.height
        Layout.preferredWidth: 1 
        radius: Theme.radiusInner
        color: previewMouseArea.containsMouse ? Theme.accent1 : Theme.colBg
        border.width: Theme.borderWidth
        border.color: Theme.accent1

        Behavior on color {
          ColorAnimation { duration: Theme.fastAnimation }
        }

        Text {
          anchors.centerIn: parent
          text: {
            const baseCount = filteredThemes.baseCount
            if (baseCount === 1) {
              const theme = filteredThemes.baseValues[0]
              return "Preview \"" + root.formatThemeName(theme ? theme.name : "") + "\""
            } else if (baseCount > 1 && root.carouselIndex >= 0) {
              const realIndex = ((root.carouselIndex % baseCount) + baseCount) % baseCount
              const theme = filteredThemes.baseValues[realIndex]
              return "Preview \"" + root.formatThemeName(theme ? theme.name : "") + "\""
            }
            return "Preview"
          }
          color: previewMouseArea.containsMouse ? Theme.colBg : Theme.accent1
          font.pixelSize: Theme.fontSizeSmall
          font.family: Theme.fontFamily
          elide: Text.ElideRight
          width: parent.width - 20
          horizontalAlignment: Text.AlignHCenter
        }

        MouseArea {
          id: previewMouseArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            const baseCount = filteredThemes.baseCount
            if (baseCount === 1) {
              const theme = filteredThemes.baseValues[0]
              if (theme) {
                awwwProcess.command = ["awww", "img", "--transition-type", "fade", "--transition-duration", "1.0", "--transition-step", "90", theme.wallpaper]
                awwwProcess.running = true
              }
            } else if (baseCount > 1 && root.carouselIndex >= 0) {
              const realIndex = ((root.carouselIndex % baseCount) + baseCount) % baseCount
              const theme = filteredThemes.baseValues[realIndex]
              if (theme) {
                awwwProcess.command = ["awww", "img", "--transition-type", "fade", "--transition-duration", "1.0", "--transition-step", "90", theme.wallpaper]
                awwwProcess.running = true
              }
            }
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: parent.height
        Layout.preferredWidth: 1
        radius: Theme.radiusInner
        color: applyMouseArea.containsMouse ? Theme.accent1 : Theme.colBg
        border.width: Theme.borderWidth
        border.color: Theme.accent1

        Behavior on color {
          ColorAnimation { duration: Theme.fastAnimation }
        }

        Text {
          anchors.centerIn: parent
          text: "Apply theme"
          color: applyMouseArea.containsMouse ? Theme.colBg : Theme.accent1
          font.pixelSize: Theme.fontSizeSmall
          font.family: Theme.fontFamily
        }

        MouseArea {
          id: applyMouseArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            const baseCount = filteredThemes.baseCount
            
            if (baseCount === 1) {
              const theme = filteredThemes.baseValues[0]
              if (theme) root.changeTheme(theme)
            } else if (baseCount > 1 && root.carouselIndex >= 0) {
              const realIndex = ((root.carouselIndex % baseCount) + baseCount) % baseCount
              const theme = filteredThemes.baseValues[realIndex]
              if (theme) root.changeTheme(theme)
            }
          }
        } 
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: parent.height
        Layout.preferredWidth: 1
        radius: Theme.radiusInner
        color: createMouseArea.containsMouse ? Theme.accent1 : Theme.colBg
        border.width: Theme.borderWidth
        border.color: Theme.accent1

        Behavior on color {
          ColorAnimation { duration: Theme.fastAnimation }
        }

        Text {
          anchors.centerIn: parent
          text: "Create new theme"
          color: createMouseArea.containsMouse ? Theme.colBg : Theme.accent1
          font.pixelSize: Theme.fontSizeSmall
          font.family: Theme.fontFamily
        }

        MouseArea {
          id: createMouseArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            StateManager.closeAllWidgets()

            for (const widget of StateManager.activeWidgets) {
              if (widget.shortcutName === "toggleCreateNewTheme") {
                widget.open()
              }
            }
          }
        }
      }
    }
  }

  Text {
    anchors.centerIn: parent
    text:
      root.themeItems.length === 0
        ? "No themes found"
        : "No matches found"
    color: Theme.colMuted
    font.pixelSize: Theme.fontSize
    font.family: Theme.fontFamily
    visible: filteredThemes.baseCount === 0
  }
}
