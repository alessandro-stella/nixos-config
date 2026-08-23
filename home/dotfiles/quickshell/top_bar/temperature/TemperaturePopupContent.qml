import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../"

Item {
  id: contentRoot

  implicitHeight: mainLayout.implicitHeight
  implicitWidth: 400

  function tempColor(temp) {
    if (temp >= 85) return Theme.colRed;
    if (temp >= 70) return Theme.colYellow;
    return Theme.colGreen;
  }

  ListModel { id: cpuTempsModel }
  ListModel { id: otherTempsModel }

  Timer {
    interval: 2000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: readAll.running = true
  }

  Process {
    id: readAll
    command: ["sh", "-c", "sensors -j | tr -d '\\n'"]
    stdout: SplitParser {
      onRead: data => {
        if (!data || data.trim() === "") return;
        try {
          let sensorsData = JSON.parse(data);
          let cpuCount = 0;
          let otherCount = 0;
          
          let nameTracker = {};

          for (let adapter in sensorsData) {
            let isCpuAdapter = adapter.match(/coretemp|k10temp/i);
            
            for (let sensorName in sensorsData[adapter]) {
              if (sensorName === "Adapter") continue;
              
              let sensor = sensorsData[adapter][sensorName];
              for (let key in sensor) {
                if (key.endsWith("_input")) {
                  let val = parseFloat(sensor[key]);
                  if (val <= 0) continue;
                  
                  let isCpuSensor = sensorName.match(/Tctl|Tccd|Package|Core/i) || isCpuAdapter;
                  
                  if (!isCpuSensor) {
                    if (sensorName.match(/Sensor\s*[0-9]+/i)) continue;
                    if (adapter.match(/acpitz/i)) continue;
                  }

                  let targetModel = isCpuSensor ? cpuTempsModel : otherTempsModel;
                  let count = isCpuSensor ? cpuCount : otherCount;
                  
                  let displayName = sensorName;
                  
                  if (isCpuSensor) {
                    if (sensorName.match(/Tctl/i)) displayName = "Control (Fans)";
                    else if (sensorName.match(/Tccd/i)) displayName = "Cores (Real)";
                    else if (sensorName.match(/Package/i)) displayName = "Package";
                  } else {
                    let baseAdapter = adapter.split("-")[0];
                    baseAdapter = baseAdapter.replace(/_wmi|_[0-9]+/g, "");
                    baseAdapter = baseAdapter.charAt(0).toUpperCase() + baseAdapter.slice(1);
                    
                    let sName = sensorName;
                    if (sName === "Composite") sName = ""; 
                    sName = sName.replace(/temp/i, "T"); 
                    
                    displayName = (baseAdapter + " " + sName).trim();
                  }

                  if (!isCpuSensor) {
                    if (nameTracker[displayName] !== undefined) {
                        nameTracker[displayName]++;
                        displayName = displayName + " " + nameTracker[displayName];
                    } else {
                        nameTracker[displayName] = 1;
                        if (displayName.match(/Nvme/i)) {
                          displayName = displayName + " 1";
                        }
                    }
                  }

                  if (displayName.length > 15) {
                    displayName = displayName.substring(0, 14) + "…";
                  }
                  
                  if (count < targetModel.count) {
                    targetModel.setProperty(count, "name", displayName);
                    targetModel.setProperty(count, "temp", val);
                  } else {
                    targetModel.append({"name": displayName, "temp": val});
                  }
                  
                  if (isCpuSensor) cpuCount++;
                  else otherCount++;
                }
              }
            }
          }
          
          while (cpuTempsModel.count > cpuCount) cpuTempsModel.remove(cpuTempsModel.count - 1);
          while (otherTempsModel.count > otherCount) otherTempsModel.remove(otherTempsModel.count - 1);
          
        } catch(e) {
          console.log("JSON parsing error: " + e)
        }
      }
    }
  }

  ColumnLayout {
    id: mainLayout
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    spacing: 20

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 12

      Text {
        text: "Processor"
        font.bold: true
        font.pixelSize: Theme.fontSize
        color: Theme.barColor
      }

      GridLayout {
        columns: 2
        Layout.fillWidth: true
        rowSpacing: 10
        columnSpacing: 20

        Repeater {
          model: cpuTempsModel

          RowLayout {
            Layout.fillWidth: true
            spacing: 8
            
            Text {
              text: model.name 
              font.pixelSize: Theme.fontSizeSmall
              color: Theme.barDarkColor
            }

            Rectangle {
              Layout.fillWidth: true
              Layout.preferredHeight: 6
              radius: 3
              color: Theme.widgetLightBackground
              
              Rectangle {
                height: parent.height
                width: parent.width * Math.max(0, Math.min(1, model.temp / 100))
                radius: 3
                color: contentRoot.tempColor(model.temp)
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 250 } }
              }
            }

            Text {
              text: Math.round(model.temp) + "°C"
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

    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 1
      color: Theme.widgetLightBackground
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 12
      
      visible: otherTempsModel.count > 0 

      Text {
        text: "Other Sensors"
        font.bold: true
        font.pixelSize: Theme.fontSize
        color: Theme.barColor
      }

      // Changed from Flow to a 3-column GridLayout
      GridLayout {
        columns: 3
        Layout.fillWidth: true
        rowSpacing: 10
        columnSpacing: 10

        Repeater {
          model: otherTempsModel
          
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 45
            color: "#1e1e2e"
            radius: 8
            border.color: Theme.widgetLightBackground
            border.width: 1

            ColumnLayout {
              anchors.centerIn: parent
              width: parent.width - 8
              spacing: 2
              
              Text {
                text: model.name
                font.pixelSize: 10
                color: Theme.barDarkColor
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
              }
              
              Text {
                text: Math.round(model.temp) + "°C"
                font.pixelSize: Theme.fontSizeSmall
                font.bold: true
                color: contentRoot.tempColor(model.temp)
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
              }
            }
          }
        }
      }
    }
  }
}
