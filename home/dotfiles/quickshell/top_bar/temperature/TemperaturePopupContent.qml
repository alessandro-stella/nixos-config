import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../"

Item {
  id: contentRoot

  implicitHeight: mainLayout.implicitHeight
  implicitWidth: 400
  
  // For Intel processors only
  property bool hasHotspot: false
  property real hotspotTemp: 0.0

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
          
          let cpuList = [];
          let otherList = [];
          
          let nameTracker = {};
          let localHasHotspot = false;
          let localHotspotTemp = 0.0;

          for (let adapter in sensorsData) {
            let isCpuAdapter = adapter.match(/coretemp|k10temp/i);
            
            for (let sensorName in sensorsData[adapter]) {
              if (sensorName === "Adapter") continue;
              
              let sensor = sensorsData[adapter][sensorName];
              for (let key in sensor) {
                if (key.match(/^temp\d+_input$/)) {
                  let val = parseFloat(sensor[key]);
                  if (val <= 0) continue;
                  
                  let isCpuSensor = sensorName.match(/Tctl|Tccd|Package|Core/i) || isCpuAdapter;
                  
                  if (!isCpuSensor) {
                    if (sensorName.match(/Sensor\s*[0-9]+/i)) continue;
                    if (adapter.match(/acpitz/i)) continue;
                  }

                  let displayName = sensorName;
                  
                  if (isCpuSensor) {
                    if (sensorName.match(/Tctl/i)) displayName = "Control (Fans)";
                    else if (sensorName.match(/Tccd/i)) displayName = "Cores (Real)";
                    else if (sensorName.match(/Package/i)) {
                      localHasHotspot = true;
                      localHotspotTemp = val;
                      continue;
                    }
                    else if (sensorName.match(/Core/i)) {
                       displayName = sensorName.replace(/Core\s*/i, "Core ");
                    }
                  } else {
                    let baseAdapter = adapter.split("-")[0];
                    baseAdapter = baseAdapter.replace(/_wmi|_[0-9]+/g, "");
                    
                    if (baseAdapter.match(/pch/i)) baseAdapter = "PCH";
                    else baseAdapter = baseAdapter.charAt(0).toUpperCase() + baseAdapter.slice(1);
                    
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
                  
                  if (isCpuSensor) {
                    cpuList.push({name: displayName, temp: val});
                  } else {
                    otherList.push({name: displayName, temp: val});
                  }
                }
              }
            }
          }

          contentRoot.hasHotspot = localHasHotspot;
          contentRoot.hotspotTemp = localHotspotTemp;

          cpuList.sort((a, b) => a.name.localeCompare(b.name, undefined, {numeric: true}));
          otherList.sort((a, b) => a.name.localeCompare(b.name, undefined, {numeric: true}));

          for (let i = 0; i < cpuList.length; i++) {
              if (i < cpuTempsModel.count) {
                  cpuTempsModel.setProperty(i, "name", cpuList[i].name);
                  cpuTempsModel.setProperty(i, "temp", cpuList[i].temp);
              } else {
                  cpuTempsModel.append(cpuList[i]);
              }
          }
          while (cpuTempsModel.count > cpuList.length) cpuTempsModel.remove(cpuTempsModel.count - 1);

          for (let i = 0; i < otherList.length; i++) {
              if (i < otherTempsModel.count) {
                  otherTempsModel.setProperty(i, "name", otherList[i].name);
                  otherTempsModel.setProperty(i, "temp", otherList[i].temp);
              } else {
                  otherTempsModel.append(otherList[i]);
              }
          }
          while (otherTempsModel.count > otherList.length) otherTempsModel.remove(otherTempsModel.count - 1);
        } catch(e) {
          console.log("JSON parsing error in TemperaturePopupContent: " + e)
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

      // Title bar
      RowLayout {
        Layout.fillWidth: true
        
        Text {
          text: "Processor"
          font.bold: true
          font.pixelSize: Theme.fontSize
          color: Theme.barColor
        }
        
        Item {
          Layout.fillWidth: true
        }
        
        Text {
          visible: contentRoot.hasHotspot
          text: "Hotspot: " + Math.round(contentRoot.hotspotTemp) + "°C"
          font.bold: true
          font.pixelSize: Theme.fontSizeSmall
          color: contentRoot.tempColor(contentRoot.hotspotTemp)
        }
      }

      // Core temp
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

    // Divider
    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 1
      color: Theme.widgetLightBackground
    }


    // Other sensors
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
