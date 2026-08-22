import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../" // Import Theme

Item {
  id: contentRoot

  readonly property real warningThreshold: 0.70
  readonly property real criticalThreshold: 0.90

  function usageColor(usage, normalColor) {
    if (usage >= criticalThreshold)
      return Theme.colRed

    if (usage >= warningThreshold)
      return Theme.colYellow

    return normalColor
  }

  readonly property color ramColor:
    usageColor(ramUsage, Theme.colGreen)

  implicitHeight: leftColumn.implicitHeight
  implicitWidth: 350

  property var lastCoreTotals: []
  property var lastCoreIdles: []
  property real ramUsage: 0.0

  ListModel {
    id: coresModel
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    triggeredOnStart: true

    onTriggered: {
      readCores.running = true
      readRam.running = true
    }
  }

  Process {
    id: readCores

    command: [
      "sh",
      "-c",
      "awk '/^cpu[0-9]+/ {printf \"%s,%s|\", $2+$3+$4+$5+$6+$7+$8, $5+$6}' /proc/stat"
    ]

    stdout: SplitParser {
      onRead: data => {
        if (!data || data.trim() === "")
          return

        let cores = data.trim().split("|")
        let newTotals = []
        let newIdles = []

        for (let i = 0; i < cores.length; i++) {
          if (cores[i] === "")
            continue

          let parts = cores[i].split(",")

          if (parts.length === 2) {
            let total = parseFloat(parts[0])
            let idle = parseFloat(parts[1])
            let usage = 0.0

            if (contentRoot.lastCoreTotals.length > i) {
              let totalDiff =
                total - contentRoot.lastCoreTotals[i]

              let idleDiff =
                idle - contentRoot.lastCoreIdles[i]

              if (totalDiff > 0) {
                usage =
                  (totalDiff - idleDiff) / totalDiff
              }
            }

            newTotals.push(total)
            newIdles.push(idle)

            if (i < coresModel.count) {
              coresModel.setProperty(i, "usage", usage)
            } else {
              coresModel.append({
                "usage": usage
              })
            }
          }
        }

        contentRoot.lastCoreTotals = newTotals
        contentRoot.lastCoreIdles = newIdles
      }
    }
  }

  Process {
    id: readRam

    command: [
      "sh",
      "-c",
      "free | awk '/Mem:/ {printf \"%f\", $3/$2}'"
    ]

    stdout: SplitParser {
      onRead: data => {
        if (!data || data.trim() === "")
          return

        let val = parseFloat(data.trim())

        if (!isNaN(val)) {
          contentRoot.ramUsage = val
        }
      }
    }
  }

  // CPU cores
  ColumnLayout {
    id: leftColumn

    anchors.left: parent.left
    anchors.top: parent.top
    anchors.right: rightContainer.left
    anchors.rightMargin: 32

    spacing: 8

    Text {
      text: "CPU Cores"

      font.bold: true
      font.pixelSize: Theme.fontSize

      color: Theme.barColor
    }

    ColumnLayout {
      id: coresContainer

      Layout.fillWidth: true
      spacing: 10

      Repeater {
        model: coresModel

        RowLayout {
          Layout.fillWidth: true
          spacing: 10

          Text {
            text: "Core " + index

            font.pixelSize: Theme.fontSizeSmall
            color: Theme.barDarkColor

            Layout.preferredWidth: 50
          }

          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 6

            radius: 3
            color: "#313244"

            Rectangle {
              height: parent.height

              width: parent.width *
                     Math.max(
                       0,
                       Math.min(1, model.usage)
                     )

              radius: 3

              color: contentRoot.usageColor(
                model.usage,
                Theme.colBlue
              )

              Behavior on width {
                NumberAnimation {
                  duration: 300
                  easing.type: Easing.OutCubic
                }
              }

              Behavior on color {
                ColorAnimation {
                  duration: 250
                }
              }
            }
          }

          Text {
            text: Math.round(model.usage * 100) + "%"

            font.pixelSize: Theme.fontSizeSmall
            font.bold: true

            color: Theme.barColor

            Layout.preferredWidth: 35

            horizontalAlignment: Text.AlignRight
          }
        }
      }
    }
  }

  // RAM
  Item {
    id: rightContainer

    anchors.right: parent.right
    anchors.top: parent.top

    width: Math.max(
      ramTitle.implicitWidth,
      ramPercentText.implicitWidth,
      36
    )

    height: leftColumn.implicitHeight

    Text {
      id: ramTitle

      text: "RAM"

      font.bold: true
      font.pixelSize: Theme.fontSize

      color: Theme.barColor

      anchors.top: parent.top
      anchors.horizontalCenter: parent.horizontalCenter
    }

    Text {
      id: ramPercentText

      text: Math.round(contentRoot.ramUsage * 100) + "%"

      font.pixelSize: Theme.fontSizeSmall
      font.bold: true

      color: contentRoot.ramColor

      anchors.top: ramTitle.bottom
      anchors.topMargin: 6
      anchors.horizontalCenter: parent.horizontalCenter

      Behavior on color {
        ColorAnimation {
          duration: 250
        }
      }
    }

    Rectangle {
      id: ramBarContainer

      anchors.top: ramPercentText.bottom
      anchors.topMargin: 8
      anchors.bottom: parent.bottom
      anchors.horizontalCenter: parent.horizontalCenter

      width: 36

      radius: 8
      color: "#313244"

      clip: true

      Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        height: parent.height * Math.max(0, Math.min(1, contentRoot.ramUsage))

        radius: 8

        color: contentRoot.ramColor

        Behavior on height {
          NumberAnimation {
            duration: 400
            easing.type: Easing.OutCubic
          }
        }

        Behavior on color {
          ColorAnimation {
            duration: 250
          }
        }
      }
    }
  }
}
