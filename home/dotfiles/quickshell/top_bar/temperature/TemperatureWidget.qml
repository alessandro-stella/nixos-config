import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../"

Rectangle {
  id: root
  required property PanelWindow parentWindow
  implicitWidth: contentRow.implicitWidth
  implicitHeight: parent.height
  color: "transparent"

  property real generalTemp: 0.0
  readonly property real criticalTemperature: 70

  Timer {
    interval: 2000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: readTemp.running = true
  }

  Process {
    id: readTemp
    // Schiacciamo il JSON su una singola riga!
    command: ["sh", "-c", "sensors -j | tr -d '\\n'"]
    stdout: SplitParser {
      onRead: data => {
        if (!data || data.trim() === "") return;
        try {
          let sensorsData = JSON.parse(data);
          let tempFound = 0.0;
          
          for (let adapter in sensorsData) {
            for (let sensorName in sensorsData[adapter]) {
              let sensor = sensorsData[adapter][sensorName];
              for (let key in sensor) {
                if (key.endsWith("_input")) {
                  let val = parseFloat(sensor[key]);
                  if (sensorName.match(/Tctl|Tccd|Package|Core/i)) {
                    tempFound = Math.max(tempFound, val);
                  } else if (tempFound === 0.0) {
                    tempFound = val;
                  }
                }
              }
            }
          }
          if (tempFound > 0) root.generalTemp = tempFound;
        } catch(e) {
          console.log("Errore parsing JSON: " + e)
        }
      }
    }
  }

  RowLayout {
    id: contentRow
    anchors.centerIn: parent
    spacing: 4

    Text {
      text: {
        if (root.generalTemp >= root.criticalTemperature) return "󱃂";
        if (root.generalTemp < 40) return "󱃃";
        return "󰔏";
      }
      font.pixelSize: Theme.barFontSize
      font.family: Theme.fontFamily
      color: root.generalTemp >= root.criticalTemperature ? Theme.colRed : Theme.barColor
    }
  }

  PopupWindow {
    id: hoverPopup
    
    anchor.window: root.parentWindow
    anchor.item: root
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom

    visible: mouseArea.containsMouse
    color: "transparent" 

    implicitWidth: tooltipRect.implicitWidth
    implicitHeight: tooltipRect.implicitHeight + Math.round(Theme.outerSpacing / 2)

    Rectangle {
      id: tooltipRect
      color: "#1e1e2e"
      border.color: Theme.accent1
      border.width: Theme.borderWidth
      radius: 6
      implicitWidth: temperatureTooltip.implicitWidth + 16
      implicitHeight: 36
      
      anchors.bottom: parent.bottom
      anchors.horizontalCenter: parent.horizontalCenter

      Text {
        id: temperatureTooltip
        anchors.centerIn: parent
        text: "General temperature: " + Math.round(root.generalTemp) + "°C"
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.barColor
      }
    }
  }

  TemperaturePopup {
    id: mainPopup
    parentWindow: root.parentWindow
    targetItem: root
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: mainPopup.toggle()
  }
}
