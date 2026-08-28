import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../"

Rectangle {
  id: root
  required property PanelWindow parentWindow
  Layout.preferredWidth: iconText.implicitWidth + 2
  implicitHeight: parent.height
  color: "transparent"

  property real generalTemp: 0.0
  property string tempLabel: "Hotspot" 
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
    command: ["sh", "-c", "sensors -j | tr -d '\\n'"]
    stdout: SplitParser {
      onRead: data => {
        if (!data || data.trim() === "") return;
        try {
          let sensorsData = JSON.parse(data);
          let tempFound = 0.0;
          let labelFound = "Hotspot";
          
          for (let adapter in sensorsData) {
            if (adapter.match(/k10temp/i)) labelFound = "Control (Fans)";

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

          if (tempFound > 0) {
            root.generalTemp = tempFound;
            root.tempLabel = labelFound;
          }
        } catch(e) {
          console.log("JSON parsing error in TemperatureWidget: " + e)
        }
      }
    }
  }

  Text {
    id: iconText
    anchors.centerIn: parent
    
    text: {
      if (root.generalTemp >= root.criticalTemperature) return "󱃂";
      if (root.generalTemp < 40) return "󱃃";
      return "󰔏";
    }

    font.pixelSize: Theme.fontSize
    font.family: Theme.fontFamily
    color: root.generalTemp >= root.criticalTemperature ? Theme.colRed : Theme.barColor
  }

  PopupWindow {
    id: hoverPopup
    
    anchor.window: root.parentWindow
    anchor.item: root
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom

    visible: mouseArea.containsMouse || tooltipRect.opacity > 0
    color: "transparent"  

    implicitWidth: tooltipRect.implicitWidth
    implicitHeight: tooltipRect.implicitHeight + Math.round(Theme.outerSpacing / 2)

    Rectangle {
      id: tooltipRect
      color: Theme.widgetDarkBackground
      border.color: Theme.accent1
      border.width: Theme.borderWidth
      radius: 6
      implicitWidth: temperatureTooltip.implicitWidth + 24
      implicitHeight: 36
      
      anchors.bottom: parent.bottom
      anchors.horizontalCenter: parent.horizontalCenter

      opacity: mouseArea.containsMouse ? 1 : 0
      scale: mouseArea.containsMouse ? 1 : 0.94

      Behavior on opacity {
        NumberAnimation {
          duration: Theme.fastAnimation
          easing.type: Easing.OutCubic
        }
      }

      Behavior on scale {
        NumberAnimation {
          duration: Theme.fastAnimation
          easing.type: Easing.OutCubic
        }
      }

      Text {
        id: temperatureTooltip
        anchors.centerIn: parent
        text: root.tempLabel + ": " + Math.round(root.generalTemp) + "°C"
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
