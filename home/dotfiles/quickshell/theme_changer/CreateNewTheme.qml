import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import "../"

ModalBackdrop {
  id: root

  required property int monitorId
  required property var modelData

  screen: modelData
  shortcutName: "toggleCreateNewTheme"

  property string tempFilePath: ""
  property int activeColorPicker: 0

  property bool showTerminalPreview: false
  property var fullPalette: StateManager.newThemePalette
  property string termBg: ""
  property string termFg: ""

  property var initialPalette: []
  property bool applyThemeOnCreate: false

  onClosed: {
    root.initialPalette = []
    root.activeColorPicker = 0
    root.showTerminalPreview = false
    root.tempFilePath = ""
    root.fullPalette = []
    StateManager.clearNewThemeState()
  }

  Process {
    id: filePickerProcess

    command: [
      "zenity",
      "--file-selection",
      "--title=Choose wallpaper",
      "--file-filter=*.png *.jpg *.jpeg *.webp"
    ]

    stdout: SplitParser {
      onRead: data => {
        if (data && data.trim() !== "")
          root.tempFilePath = data.trim()
      }
    }

    onExited: {
      for (const widget of StateManager.activeWidgets) {
        if (widget.shortcutName === "toggleCreateNewTheme")
          widget.open()
      }

      if (root.tempFilePath !== "") {
        StateManager.newThemeImagePath = root.tempFilePath
        root.tempFilePath = ""

        if (sddmAccentExtractor.running)
          sddmAccentExtractor.kill()

        sddmAccentExtractor.command = [
          "sh",
          Quickshell.env("HOME") + "/.config/quickshell/theme_changer/scripts/get_sddm_accents.sh",
          StateManager.newThemeImagePath
        ]
        sddmAccentExtractor.running = true

        if (paletteExtractor.running)
          paletteExtractor.kill()

        paletteExtractor.command = [
          "sh",
          Quickshell.env("HOME") + "/.config/quickshell/theme_changer/scripts/get_palette.sh",
          StateManager.newThemeImagePath
        ]
        paletteExtractor.running = true
      }
    }
  }

  Process {
    id: sddmAccentExtractor

    stdout: SplitParser {
      onRead: data => {
        try {
          const parsed = JSON.parse(data.trim())
          if (parsed.accent1) StateManager.newThemeColor1 = parsed.accent1
          if (parsed.accent2) StateManager.newThemeColor2 = parsed.accent2
        } catch (e) {
          console.log("SDDM Accents JSON error:", e)
        }
      }
    }

    stderr: SplitParser {
      onRead: data => {
        console.log("SDDM Accent extractor error:", data)
      }
    }
  }

  Process {
    id: paletteExtractor

    stdout: SplitParser {
      onRead: data => {
        try {
          const parsed = JSON.parse(data)

          if (parsed.palette && Array.isArray(parsed.palette)) {
            StateManager.newThemePalette = parsed.palette
            root.fullPalette = StateManager.newThemePalette

            if (root.initialPalette.length === 0) {
              root.initialPalette = parsed.palette.slice()
            }

            root.termBg = parsed.background || ""
            root.termFg = parsed.foreground || ""
          }
        } catch (e) {
          console.log("Palette JSON error:", e)
        }
      }
    }

    stderr: SplitParser {
      onRead: data => {
        console.log("Palette extractor error:", data)
      }
    }
  }

  Process {
    id: colorPickerProcess

    stdout: SplitParser {
      onRead: data => {
        const color = data.trim()

        if (!color.startsWith("#"))
          return

        if (root.activeColorPicker === 1) {
          StateManager.newThemeColor1 = color

        } else if (root.activeColorPicker === 2) {
          StateManager.newThemeColor2 = color

        } else if (
          root.activeColorPicker >= 3
          && root.activeColorPicker <= 11
        ) {
          const paletteIndex =
            root.activeColorPicker - 3

          const palette =
            StateManager.newThemePalette.slice()

          palette[paletteIndex] = color

          StateManager.newThemePalette = palette
          root.fullPalette = palette
        }

        root.activeColorPicker = 0
      }
    }
  }

  Process {
    id: themeCreator

    stdout: SplitParser {
      onRead: data => {
        if (data.includes("[✓]")) {
          console.log("✓ " + data)
        } else if (data.includes("[INFO]")) {
          console.log("ℹ " + data)
        }
      }
    }

    stderr: SplitParser {
      onRead: data => {
        console.error("✗ Theme error: " + data)
      }
    }

    onExited: {
      console.log("=== Theme creation completed ===")
    }
  }

  function createTheme(apply) {
    const wallpaperPath = StateManager.newThemeImagePath
    const paletteArray = StateManager.newThemePalette
    const accent1 = StateManager.newThemeColor1
    const accent2 = StateManager.newThemeColor2

    const paletteJson = JSON.stringify(paletteArray)

    const args = [
      "bash",
      Quickshell.env("HOME") + "/.config/quickshell/theme_changer/scripts/create_theme.sh",
      "--wallpaper", wallpaperPath,
      "--palette", paletteJson,
      "--accent1", accent1,
      "--accent2", accent2
    ]

    if (apply) {
      args.push("--apply")
    }

    themeCreator.command = args
    themeCreator.running = true

    StateManager.clearNewThemeState()
    StateManager.closeAllWidgets()
  }

  FocusScope {
    anchors.fill: parent
    focus: true

    Rectangle {
      id: mainBox

      anchors.centerIn: parent

      width: 1000
      height: 580

      radius: Theme.radiusOuter
      color: Theme.colBg

      border.color: Theme.accent1
      border.width: Theme.borderWidth

      MouseArea {
        anchors.fill: parent
        onClicked: {}
      }

      Item {
        anchors.fill: parent
        anchors.margins: 16

        ColumnLayout {
          anchors.left: parent.left
          anchors.right: rightColumn.left
          anchors.rightMargin: 24
          anchors.top: parent.top
          anchors.bottom: parent.bottom

          spacing: 15

          Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true

            radius: Theme.radiusInner

            color: Theme.widgetLightBackground

            border.color:
              root.activeColorPicker !== 0
              ? Theme.colGreen
              : Theme.colMuted

            border.width: Theme.borderWidth

            clip: true

            Behavior on border.color {
              ColorAnimation {
                duration: Theme.fastAnimation
              }
            }

            Image {
              id: previewImg

              anchors.fill: parent
              anchors.margins: Theme.borderWidth

              source:
                StateManager.newThemeImagePath !== ""
                ? "file://" + StateManager.newThemeImagePath
                : ""

              fillMode: Image.PreserveAspectCrop

              visible:
                StateManager.newThemeImagePath !== ""

              layer.enabled: true

              layer.effect: MultiEffect {
                maskEnabled: true

                maskSource: ShaderEffectSource {
                  sourceItem: Rectangle {
                    width: previewImg.width
                    height: previewImg.height
                    radius: Theme.radiusInner - 1
                    color: "white"
                  }

                  hideSource: true
                }
              }
            }

            Item {
              id: terminalOverlay

              anchors.fill: parent
              anchors.margins: 16

              visible:
                root.showTerminalPreview
                && StateManager.newThemeImagePath !== ""
                && root.fullPalette.length > 0

              clip: true

              ShaderEffectSource {
                id: termBlurSource

                sourceItem: previewImg

                sourceRect: Qt.rect(
                  16 - Theme.borderWidth,
                  16 - Theme.borderWidth,
                  terminalOverlay.width,
                  terminalOverlay.height
                )

                visible: false
              }

              ShaderEffectSource {
                id: termMaskSource

                sourceItem: Rectangle {
                  width: terminalOverlay.width
                  height: terminalOverlay.height
                  radius: Theme.radiusInner
                  color: "white"
                }

                hideSource: true
              }

              MultiEffect {
                id: terminalBlur

                anchors.fill: parent

                source: termBlurSource

                blurEnabled: true
                blurMax: 64
                blur: 0.5

                maskEnabled: true
                maskSource: termMaskSource
              }

              Rectangle {
                anchors.fill: parent

                radius: Theme.radiusInner

                border.color: StateManager.newThemeColor1
                border.width: 1

                color:
                  root.termBg !== ""
                  ? root.termBg + "66"
                  : "#12111466"

                clip: true

                Behavior on border.color {
                  ColorAnimation {
                    duration: Theme.fastAnimation
                  }
                }

                Text {
                  anchors.fill: parent
                  anchors.margins: 24

                  textFormat: Text.RichText

                  font.family: "monospace"
                  font.pixelSize: Theme.fontSizeSmall

                  color: root.termFg
                  lineHeight: 1.4

                  text: {
                    if (root.fullPalette.length < 9)
                      return ""

                    const p = root.fullPalette
                    const fg = root.termFg

                    const ac1 = StateManager.newThemeColor1
                    const ac2 = StateManager.newThemeColor2

                    return `
                      <span style="color:${ac1}"><b>user@nixos</b></span>:<span style="color:${ac2}"><b>~/Downloads</b></span>$ ls -la<br>
                      <span style="color:${fg}">total 48</span><br>
                      <span style="color:${fg}">drwxr-xr-x 2 user users 4096 Aug 26 11:21 </span><span style="color:${p[4]}"><b>projects</b></span><br>
                      <span style="color:${fg}">-rwxr-xr-x 1 user users 50K Aug 26 11:21 </span><span style="color:${p[2]}"><b>run.sh</b></span>*<br>
                      <span style="color:${fg}">-rw-r--r-- 1 user users 1.2M Aug 26 11:21 </span><span style="color:${p[1]}"><b>backup.zip</b></span><br>
                      <span style="color:${fg}">-rw-r--r-- 1 user users 2.5M Aug 26 11:21 </span><span style="color:${p[5]}"><b>video.mp4</b></span><br>
                      <span style="color:${fg}">srwxr-xr-x 1 user users 0 Aug 26 11:21 </span><span style="color:${p[5]}"><b>socket</b></span><br>
                      <span style="color:${fg}">lrwxrwxrwx 1 user users 12 Aug 26 11:21 </span><span style="color:${p[6]}"><b>music</b></span><span style="color:${fg}"> -&gt; /var/music</span><br>
                      <span style="color:${fg}">-rw-r--r-- 1 user users 4.2M Aug 26 11:21 </span><span style="color:${p[6]}">song.flac</span><br>
                      <span style="background-color:${p[0]}; color:${p[3]}">prw-r--r-- 1 user users 0 Aug 26 11:21 pipe</span><br>
                      <span style="color:${fg}">-rw------- 1 user users 12K Aug 26 11:21 </span><span style="color:${p[8]}">temp.tmp</span><br>
                      <span style="color:${fg}">-rw-r--r-- 1 user users 1.4K Aug 26 11:21 normal.txt</span><br>
                      <br>
                      <span style="color:${ac1}"><b>user@nixos</b></span>:<span style="color:${ac2}"><b>~/Downloads</b></span>$ <span style="background-color:${fg}; color:transparent">_</span>
                      `
                  }
                }
              }
            }

            Text {
              anchors.centerIn: parent

              text: "No image selected"

              horizontalAlignment: Text.AlignHCenter

              color: Theme.colMuted

              font.pixelSize: Theme.fontSize
              font.family: Theme.fontFamily

              visible:
                StateManager.newThemeImagePath === ""
            }

            Rectangle {
              id: magnifier

              width: 120
              height: 120

              border.color: Theme.accent1
              border.width: 2

              z: 100

              visible:
                root.activeColorPicker !== 0
                && pickMouseArea.containsMouse
                && StateManager.newThemeImagePath !== ""
                && !root.showTerminalPreview

              x:
                pickMouseArea.mouseX - width / 2

              y:
                pickMouseArea.mouseY - height - 15

              onYChanged: {
                if (y < 0)
                  y = pickMouseArea.mouseY + 25
              }

              ShaderEffectSource {
                id: zoomSource

                anchors.fill: parent
                anchors.margins: magnifier.border.width

                sourceItem: previewImg

                sourceRect: Qt.rect(
                  pickMouseArea.mouseX - 10,
                  pickMouseArea.mouseY - 10,
                  20,
                  20
                )

                layer.enabled: true

                layer.effect: MultiEffect {
                  maskEnabled: true

                  maskSource: ShaderEffectSource {
                    sourceItem: Rectangle {
                      width: zoomSource.width
                      height: zoomSource.height

                      radius: width / 2
                      color: "white"
                    }

                    hideSource: true
                  }
                }
              }

              Rectangle {
                anchors.centerIn: parent

                width: 4
                height: 4

                radius: 2

                color: Theme.colRed
              }
            }

            MouseArea {
              id: pickMouseArea

              anchors.fill: parent

              hoverEnabled: true

              enabled:
                root.activeColorPicker !== 0
                && StateManager.newThemeImagePath !== ""
                && !root.showTerminalPreview

              cursorShape:
                enabled
                ? Qt.CrossCursor
                : Qt.ArrowCursor

              onClicked: mouse => {
                if (previewImg.sourceSize.width === 0)
                  return

                const scale =
                  Math.max(
                    previewImg.width
                    / previewImg.sourceSize.width,
                    previewImg.height
                    / previewImg.sourceSize.height
                  )

                const visibleW =
                  previewImg.width / scale

                const visibleH =
                  previewImg.height / scale

                const offsetX =
                  (
                    previewImg.sourceSize.width
                    - visibleW
                  ) / 2

                const offsetY =
                  (
                    previewImg.sourceSize.height
                    - visibleH
                  ) / 2

                const realX =
                  Math.floor(
                    offsetX + mouse.x / scale
                  )

                const realY =
                  Math.floor(
                    offsetY + mouse.y / scale
                  )

                colorPickerProcess.command = [
                  "sh",
                  "-c",
                  `magick "${StateManager.newThemeImagePath}" -crop 1x1+${realX}+${realY} txt: | grep -oE '#[0-9A-Fa-f]{6}' | head -n 1`
                ]

                colorPickerProcess.running = true
              }
            }
          }

          RowLayout {
            Rectangle {
              Layout.fillWidth: true
              Layout.preferredHeight: 45

              radius: Theme.radiusInner

              color:
                chooseFileMouseArea.containsMouse
                ? Theme.accent1
                : Theme.colBg

              border.width: Theme.borderWidth
              border.color: Theme.accent1

              Behavior on color {
                ColorAnimation {
                  duration: Theme.fastAnimation
                }
              }

              Text {
                anchors.centerIn: parent

                text: "Choose wallpaper"

                color:
                  chooseFileMouseArea.containsMouse
                  ? Theme.colBg
                  : Theme.accent1

                font.pixelSize: Theme.fontSizeSmall
                font.family: Theme.fontFamily
              }

              MouseArea {
                id: chooseFileMouseArea

                anchors.fill: parent

                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: {
                  StateManager.closeAllWidgets()
                  filePickerProcess.running = true
                }
              }
            }

            Rectangle {
              Layout.fillWidth: true
              Layout.preferredHeight: 45
  
              radius: Theme.radiusInner
  
              color:
                cancelMouseArea.containsMouse
                ? Theme.accent1
                : Theme.colBg
  
              border.width: Theme.borderWidth
              border.color: Theme.accent1

              Behavior on color {
                ColorAnimation {
                  duration: Theme.fastAnimation
                }
              }
  
              Text {
                anchors.centerIn: parent
  
                text: "Select existing theme"
  
                color:
                  cancelMouseArea.containsMouse
                  ? Theme.colBg
                  : Theme.accent1
  
                font.pixelSize: Theme.fontSizeSmall
                font.family: Theme.fontFamily
              }
  
              MouseArea {
                id: cancelMouseArea
  
                anchors.fill: parent
  
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
  
                onClicked: {
                  StateManager.clearNewThemeState()
                  StateManager.closeAllWidgets()
  
                  for (const widget of StateManager.activeWidgets) {
                    console.log("Widget:", widget)
                    if (widget.shortcutName === "toggleThemeChanger") {
                      widget.open()
                    }
                  }
                }
              }
            }
          }
        }

        ColumnLayout {
          id: rightColumn

          anchors.right: parent.right
          anchors.top: parent.top
          anchors.bottom: parent.bottom

          width: 300
          spacing: 12

          Text {
            text: "Creating new theme"

            color: Theme.accent1

            font.pixelSize: Theme.fontSize
            font.family: Theme.fontFamily
            font.bold: true
          }

          Text {
            text: "Accent colors"

            color: Theme.colFg

            font.pixelSize: Theme.fontSizeSmall
            font.family: Theme.fontFamily
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
              width: 28
              height: 28

              radius: Theme.radiusInner

              color: StateManager.newThemeColor1

              border.color: Theme.accent1
              border.width: 1

              Behavior on color {
                ColorAnimation {
                  duration: Theme.fastAnimation
                }
              }
            }

            TextField {
              Layout.fillWidth: true

              text: StateManager.newThemeColor1

              color: Theme.colFg

              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontSizeSmall

              background: Rectangle {
                color: "#24283b"
                radius: Theme.radiusInner

                border.color:
                  parent.activeFocus
                  ? Theme.accent1
                  : Theme.colMuted
              }

              onTextChanged: {
                if (StateManager.newThemeColor1 !== text)
                  StateManager.newThemeColor1 = text
              }
            }

            Rectangle {
              width: 29
              height: 29

              radius: Theme.radiusInner

              color:
                root.activeColorPicker === 1
                ? Theme.colGreen
                : Theme.colBg

              border.color:
                root.activeColorPicker === 1
                ? Theme.colGreen
                : Theme.accent1

              border.width: 1

              Behavior on color {
                ColorAnimation {
                  duration: Theme.fastAnimation
                }
              }

              Behavior on border.color {
                ColorAnimation {
                  duration: Theme.fastAnimation
                }
              }

              Text {
                anchors.centerIn: parent

                text: "⌖"
                color: root.activeColorPicker === 1
                  ? Theme.widgetDarkBackground
                  : Theme.colFg

                font.pixelSize: 16
              }

              MouseArea {
                anchors.fill: parent

                cursorShape: StateManager.newThemeImagePath !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor

                onClicked: {
                  if (StateManager.newThemeImagePath === "")
                    return

                  root.showTerminalPreview = false

                  root.activeColorPicker =
                    root.activeColorPicker === 1
                    ? 0
                    : 1
                }
              }
            }
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
              width: 28
              height: 28

              radius: Theme.radiusInner

              color: StateManager.newThemeColor2

              border.color: Theme.accent1
              border.width: 1

              Behavior on color {
                ColorAnimation {
                  duration: Theme.fastAnimation
                }
              }
            }

            TextField {
              Layout.fillWidth: true

              text: StateManager.newThemeColor2

              color: Theme.colFg

              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontSizeSmall

              background: Rectangle {
                color: "#24283b"
                radius: Theme.radiusInner

                border.color:
                  parent.activeFocus
                  ? Theme.accent1
                  : Theme.colMuted
              }

              onTextChanged: {
                if (StateManager.newThemeColor2 !== text)
                  StateManager.newThemeColor2 = text
              }
            }

            Rectangle {
              width: 29
              height: 29

              radius: Theme.radiusInner

              color:
                root.activeColorPicker === 2
                ? Theme.colGreen
                : Theme.colBg

              border.color:
                root.activeColorPicker === 2
                ? Theme.colGreen
                : Theme.accent1

              border.width: 1

              Behavior on color {
                ColorAnimation {
                  duration: Theme.fastAnimation
                }
              }

              Behavior on border.color {
                ColorAnimation {
                  duration: Theme.fastAnimation
                }
              }

              Text {
                anchors.centerIn: parent

                text: "⌖"
                color: root.activeColorPicker === 1
                  ? Theme.widgetDarkBackground
                  : Theme.colFg

                font.pixelSize: 16
              }

              MouseArea {
                anchors.fill: parent

                cursorShape: StateManager.newThemeImagePath !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor

                onClicked: {
                  if (StateManager.newThemeImagePath === "")
                    return

                  root.showTerminalPreview = false

                  root.activeColorPicker =
                    root.activeColorPicker === 2
                    ? 0
                    : 2
                }
              }
            }
          }

          Text {
            text: "Terminal palette"

            color: Theme.colFg

            font.pixelSize: Theme.fontSizeSmall
            font.family: Theme.fontFamily
          }

          GridLayout {
            id: paletteGrid

            Layout.fillWidth: true

            columns: 2

            columnSpacing: 8
            rowSpacing: 8

            Repeater {
              model: 8

              delegate: RowLayout {
                required property int index

                Layout.fillWidth: true
                spacing: 5

                Rectangle {
                  id: paletteColor

                  width: 24
                  height: 28

                  radius: Theme.radiusInner

                  color:
                    root.fullPalette.length > index
                    ? root.fullPalette[index]
                    : Theme.colBg

                  border.color:
                    root.activeColorPicker === index + 3
                    ? Theme.colGreen
                    : Theme.accent1

                  border.width:
                    root.activeColorPicker === index + 3
                    ? 2
                    : 1

                  Behavior on color {
                    ColorAnimation {
                      duration: Theme.fastAnimation
                    }
                  }

                  Behavior on border.color {
                    ColorAnimation {
                      duration: Theme.fastAnimation
                    }
                  }

                  MouseArea {
                    id: paletteColorMouseArea

                    anchors.fill: parent

                    hoverEnabled: StateManager.newThemeImagePath !== ""
                    
                    cursorShape: StateManager.newThemeImagePath !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor

                    onClicked: {
                      if (StateManager.newThemeImagePath === "")
                        return

                      root.showTerminalPreview = false

                      root.activeColorPicker =
                        root.activeColorPicker === index + 3
                        ? 0
                        : index + 3
                    }
                  }

                  Rectangle {
                    anchors.fill: parent

                    radius: parent.radius

                    color: Theme.colGreen

                    opacity:
                      (paletteColorMouseArea.containsMouse && !paletteColorMouseArea.pressed)
                      ? 0.85
                      : 0

                    Behavior on opacity {
                      NumberAnimation {
                        duration: Theme.fastAnimation
                      }
                    }

                    Text {
                      anchors.centerIn: parent

                      text: "⌖"

                      color: Theme.widgetDarkBackground

                      font.pixelSize: 15

                      opacity:
                        (paletteColorMouseArea.containsMouse && !paletteColorMouseArea.pressed)
                        ? 1
                        : 0

                      Behavior on opacity {
                        NumberAnimation {
                          duration: Theme.fastAnimation
                        }
                      }
                    }
                  }
                }

                TextField {
                  Layout.fillWidth: true

                  text:
                    root.fullPalette.length > index
                    ? root.fullPalette[index]
                    : ""

                  color: Theme.colFg

                  font.family: Theme.fontFamily
                  font.pixelSize: Theme.fontSizeSmall

                  leftPadding: 6
                  rightPadding: 6

                  background: Rectangle {
                    color: "#24283b"

                    radius: Theme.radiusInner

                    border.color:
                      parent.activeFocus
                      ? Theme.accent1
                      : Theme.colMuted
                  }

                  onTextChanged: {
                    if (
                      root.fullPalette.length > index
                      && root.fullPalette[index] !== text
                    ) {
                      const palette =
                        StateManager.newThemePalette.slice()

                      palette[index] = text

                      StateManager.newThemePalette = palette
                      root.fullPalette = palette
                    }
                  }
                }
              }
            }
          }

          Item {
            Layout.fillHeight: true
            width: 1
          }

          RowLayout {
          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 45

            radius: Theme.radiusInner

            color: resetPaletteArea.containsMouse ? Theme.colRed : "transparent"

            border.width: Theme.borderWidth
            border.color: Theme.colRed

            opacity: StateManager.newThemeImagePath !== "" ? 1.0 : 0.5

            Behavior on color {
              ColorAnimation {
                duration: Theme.fastAnimation
              }
            }

            Text {
              anchors.centerIn: parent

              text: "Reset palette"

              color:
                resetPaletteArea.containsMouse
                ? Theme.widgetDarkBackground
                : Theme.colRed

              font.pixelSize: Theme.fontSizeSmall
              font.family: Theme.fontFamily
            }

            MouseArea {
              id: resetPaletteArea 

              anchors.fill: parent

              hoverEnabled: StateManager.newThemeImagePath !== ""
              cursorShape: StateManager.newThemeImagePath !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor

              enabled: StateManager.newThemeImagePath !== ""

              onClicked: {
                root.activeColorPicker = 0

                if (root.initialPalette && root.initialPalette.length > 0) {
                  const paletteCopy = root.initialPalette.slice()
                  StateManager.newThemePalette = paletteCopy
                  root.fullPalette = paletteCopy
                }

                root.showTerminalPreview = false
              }
            }
          }

          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 45

            radius: Theme.radiusInner

            color:
              toggleTerminalArea.containsMouse
              ? Theme.accent1
              : "transparent"

            border.width: Theme.borderWidth
            border.color: Theme.accent1

            opacity:
              StateManager.newThemeImagePath !== ""
              ? 1.0
              : 0.5

            Behavior on color {
              ColorAnimation {
                duration: Theme.fastAnimation
              }
            }

            Text {
              anchors.centerIn: parent

              text:
                root.showTerminalPreview
                ? "Hide preview"
                : "Show preview"

              color:
                toggleTerminalArea.containsMouse
                ? Theme.widgetDarkBackground
                : Theme.accent1

              font.pixelSize: Theme.fontSizeSmall
              font.family: Theme.fontFamily
            }

            MouseArea {
              id: toggleTerminalArea

              anchors.fill: parent

              hoverEnabled: StateManager.newThemeImagePath !== ""
              cursorShape: StateManager.newThemeImagePath !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor

              enabled:
                StateManager.newThemeImagePath !== ""

              onClicked: {
                root.activeColorPicker = 0

                root.showTerminalPreview =
                  !root.showTerminalPreview
              }
            }
          }
          }

          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 45

            radius: Theme.radiusInner

            color:
              createMouseArea.containsMouse
              ? Theme.colGreen
              : Theme.colBg

            border.width: Theme.borderWidth
            border.color: Theme.colGreen

            opacity:
              StateManager.newThemeImagePath !== ""
              ? 1.0
              : 0.5

            Behavior on color {
              ColorAnimation {
                duration: Theme.fastAnimation
              }
            }

            Text {
              anchors.centerIn: parent

              text: "Create theme"

              color:
                createMouseArea.containsMouse
                ? Theme.widgetDarkBackground
                : Theme.colGreen

              font.pixelSize: Theme.fontSizeSmall
              font.family: Theme.fontFamily

              font.bold: true
            }

            MouseArea {
              id: createMouseArea

              anchors.fill: parent

              hoverEnabled: StateManager.newThemeImagePath !== ""
              cursorShape: StateManager.newThemeImagePath !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor

              enabled:
                StateManager.newThemeImagePath !== ""

              onClicked: {
                root.createTheme(false)
              }
            }
          }

          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 45

            radius: Theme.radiusInner

            color:
              createAndApplyMouseArea.containsMouse
              ? Theme.colGreen
              : Theme.colBg

            border.width: Theme.borderWidth
            border.color: Theme.colGreen

            opacity:
              StateManager.newThemeImagePath !== ""
              ? 1.0
              : 0.5

            Behavior on color {
              ColorAnimation {
                duration: Theme.fastAnimation
              }
            }

            Text {
              anchors.centerIn: parent

              text: "Create and apply theme"

              color:
                createAndApplyMouseArea.containsMouse
                ? Theme.widgetDarkBackground
                : Theme.colGreen

              font.pixelSize: Theme.fontSizeSmall
              font.family: Theme.fontFamily

              font.bold: true
            }

            MouseArea {
              id: createAndApplyMouseArea

              anchors.fill: parent

              hoverEnabled: StateManager.newThemeImagePath !== ""
              cursorShape: StateManager.newThemeImagePath !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor

              enabled:
                StateManager.newThemeImagePath !== ""

              onClicked: {
                root.createTheme(true)
              }
            }
          }
        }
      }
    }
  }
}
