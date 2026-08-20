import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.UPower
import "../"

Scope {
  id: popupScope

  required property Item targetItem
  required property PanelWindow parentWindow
  required property bool sysfsBatteryExists
  
  property bool isOpen: false
  property bool _isLoaded: false

  function toggle() {
    if (!isOpen) {
      _isLoaded = true
      isOpen = true
    } else {
      isOpen = false
    }
  }

  Loader {
    active: popupScope._isLoaded && popupScope.sysfsBatteryExists
    sourceComponent: popupContentComponent
  }

  Component {
    id: popupContentComponent
    
    Scope {
      id: innerScope

      Connections {
        target: popupScope
        function onIsOpenChanged() {
          if (popupScope.isOpen) {
            popup.visible = true
            card.forceActiveFocus()
            getTlpMode.running = true
            if (!card.useNative) readSysfs.running = true
          }
        }
      }

      Component.onCompleted: {
        if (popupScope.isOpen) {
          popup.visible = true
          card.forceActiveFocus()
          getTlpMode.running = true
          if (!card.useNative) readSysfs.running = true
        }
      }

      QtObject {
        id: sysfsBattery
        property real percentage: 0.0
        property string rawStatus: "Unknown"
        property real timeRemaining: 0
        property real powerRateW: 0
        property real energyWh: 0
        property real energyCapacityWh: 0
        property real health: 1.0
      }

      Timer {
        id: batteryPoller
        interval: 4000
        running: popupScope.isOpen && !card.useNative
        repeat: true
        onTriggered: readSysfs.running = true
      }

      Process {
        id: readSysfs
        command: ["sh", "-c", "
          bat=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -n1);
          if [ -n \"$bat\" ]; then
            cap=$(cat $bat/capacity 2>/dev/null || echo 0);
            stat=$(cat $bat/status 2>/dev/null || echo Unknown);
            now=$(cat $bat/energy_now 2>/dev/null || cat $bat/charge_now 2>/dev/null || echo 0);
            full=$(cat $bat/energy_full 2>/dev/null || cat $bat/charge_full 2>/dev/null || echo 0);
            design=$(cat $bat/energy_full_design 2>/dev/null || cat $bat/charge_full_design 2>/dev/null || echo 0);
            rate=$(cat $bat/power_now 2>/dev/null || cat $bat/current_now 2>/dev/null || echo 0);
            echo \"$cap|$stat|$now|$full|$design|$rate\";
          fi
        "]
        stdout: SplitParser {
          onRead: data => {
            if (!data || data.trim() === "") return;
            const p = data.trim().split("|");
            if (p.length >= 6) {
              sysfsBattery.percentage = parseFloat(p[0]) / 100.0;
              sysfsBattery.rawStatus = p[1].trim();
              
              const nowUwh = parseFloat(p[2]) || 0;
              const fullUwh = parseFloat(p[3]) || 0;
              const designUwh = parseFloat(p[4]) || 0;
              const rateUw = parseFloat(p[5]) || 0;

              sysfsBattery.energyWh = nowUwh / 1000000.0;
              sysfsBattery.energyCapacityWh = fullUwh / 1000000.0;
              sysfsBattery.powerRateW = rateUw / 1000000.0;
              sysfsBattery.health = designUwh > 0 ? (fullUwh / designUwh) : 1.0;

              const st = sysfsBattery.rawStatus.toLowerCase();
              if (st === "discharging" && rateUw > 0 && nowUwh > 0) {
                sysfsBattery.timeRemaining = (nowUwh / rateUw) * 3600;
              } else if (st === "charging" && rateUw > 0 && fullUwh > nowUwh) {
                sysfsBattery.timeRemaining = ((fullUwh - nowUwh) / rateUw) * 3600;
              } else {
                sysfsBattery.timeRemaining = 0;
              }
            }
          }
        }
      }

      PanelWindow {
        id: clickOutsideBackdrop
        screen: popupScope.parentWindow.screen
        visible: popupScope.isOpen
        color: "transparent"
        
        anchors {
          top: true
          bottom: true
          left: true
          right: true
        } 
        
        WlrLayershell.layer: WlrLayer.Top

        MouseArea {
          anchors.fill: parent
          onClicked: popupScope.isOpen = false
        }
      }

      PopupWindow {
        id: popup
        anchor.window: popupScope.parentWindow
        anchor.item: popupScope.targetItem
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom

        visible: false
        color: "transparent"

        implicitWidth: 300
        implicitHeight: contentLayout.implicitHeight + 36

        Rectangle {
          id: card
          anchors.fill: parent
          anchors.topMargin: 5
          color: Theme.colBg ?? "#1e1e2e"
          radius: Theme.radiusOuter
          border.color: Theme.accent1
          border.width: Theme.borderWidth
          clip: true

          property string activeMode: "auto"

          readonly property var dev: UPower.displayDevice
          readonly property bool useNative: dev && dev.ready

          readonly property real batteryPct: useNative ? dev.percentage : sysfsBattery.percentage
          readonly property real batteryWatts: useNative ? dev.changeRate : sysfsBattery.powerRateW
          readonly property real batteryHealth: useNative && dev.healthSupported ? dev.healthPercentage : sysfsBattery.health
          readonly property real batteryEnergy: useNative ? dev.energy : sysfsBattery.energyWh
          readonly property real batteryCapacity: useNative ? dev.energyCapacity : sysfsBattery.energyCapacityWh

          readonly property string statusText: {
            if (useNative) {
              switch(dev.state) {
                case UPowerDeviceState.Charging: return "Charging";
                case UPowerDeviceState.Discharging: return "Discharging";
                case UPowerDeviceState.FullyCharged: return "Fully Charged";
                case UPowerDeviceState.Empty: return "Empty";
                case UPowerDeviceState.PendingCharge: return "Threshold Hold (AC)";
                case UPowerDeviceState.PendingDischarge: return "Threshold Hold (BAT)";
                default: return "Idle";
              }
            }
            const s = sysfsBattery.rawStatus.toLowerCase();
            if (s === "charging") return "Charging";
            if (s === "discharging") return "Discharging";
            if (s === "full") return "Fully Charged";
            if (s === "not charging") return "Threshold Hold (AC)";
            return sysfsBattery.rawStatus;
          }

          readonly property color statusColor: {
            if (statusText === "Charging" || statusText === "Fully Charged") return "#a6e3a1";
            if (statusText.indexOf("Threshold Hold") !== -1) return "#89b4fa";
            if (batteryPct <= 0.15) return "#f38ba8";
            return Theme.colSubtext ?? "#a6adc8";
          }

          readonly property string timeRemainingText: {
            let sec = 0;
            if (useNative) {
              sec = (dev.state === UPowerDeviceState.Charging) ? dev.timeToFull : dev.timeToEmpty;
            } else {
              sec = sysfsBattery.timeRemaining;
            }

            if (statusText.indexOf("Threshold Hold") !== -1) return "Passthrough";
            if (!sec || sec <= 0) return "Estimating...";
            const h = Math.floor(sec / 3600);
            const m = Math.floor((sec % 3600) / 60);
            return (h > 0 ? (h + "h ") : "") + m + "m";
          }

          transformOrigin: Item.Top
          opacity: popupScope.isOpen ? 1 : 0
          scale: popupScope.isOpen ? 1 : 0.94
          focus: popupScope.isOpen

          Keys.onPressed: (event) => {
            popupScope.isOpen = false;
            event.accepted = true;
          }

          Behavior on opacity {
            NumberAnimation { duration: Theme.slowAnimation; easing.type: Easing.OutCubic }
          }

          Behavior on scale {
            NumberAnimation { duration: Theme.slowAnimation; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
          }

          onOpacityChanged: {
            if (opacity === 0 && !popupScope.isOpen) {
              popup.visible = false;
            }
          }

          Process {
            id: getTlpMode
            command: ["sh", "-c", "tlp-stat -s 2>/dev/null | awk '/Mode/ {print tolower($3)}'"]
            running: false 
            stdout: SplitParser {
              onRead: data => {
                if (data && data.trim() !== "") {
                  card.activeMode = data.trim();
                }
              }
            }
          }

          ColumnLayout {
            id: contentLayout
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            // Header
            RowLayout {
              Layout.fillWidth: true

              Text {
                text: "Battery"
                font.bold: true
                font.pixelSize: Theme.fontSize
                color: Theme.colFg ?? "#cdd6f4"
                Layout.fillWidth: true
              }

              Text {
                text: card.statusText
                font.pixelSize: Theme.fontSizeSmall
                font.bold: true
                color: card.statusColor
              }
            }

            // Percentage + Rate
            RowLayout {
              Layout.fillWidth: true

              Text {
                text: Math.round(card.batteryPct * 100) + "%"
                font.bold: true
                font.pixelSize: 24
                color: Theme.colFg ?? "#cdd6f4"
              }

              Item { Layout.fillWidth: true }

              Text {
                text: Math.abs(card.batteryWatts).toFixed(1) + " W"
                font.pixelSize: Theme.fontSizeSmall
                font.bold: true
                color: card.batteryWatts > 0 ? "#a6e3a1" : (card.batteryWatts < 0 ? "#fab387" : (Theme.colSubtext ?? "#a6adc8"))
                visible: Math.abs(card.batteryWatts) > 0
              }
            }

            // Progress Bar
            Rectangle {
              Layout.fillWidth: true
              implicitHeight: 6
              radius: 3
              color: "#313244"

              Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * Math.max(0, Math.min(1, card.batteryPct))
                radius: 3
                color: card.statusText.indexOf("Threshold Hold") !== -1 ? "#89b4fa" : (card.batteryPct <= 0.15 ? "#f38ba8" : (card.batteryPct <= 0.30 ? "#fab387" : "#a6e3a1"))

                Behavior on width {
                  NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                }
              }
            }

            // Details - Time Remaining
            RowLayout {
              Layout.fillWidth: true
              Text {
                text: (card.statusText === "Charging") ? "Time to full" : "Remaining time"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.colSubtext ?? "#a6adc8"
              }
              Item { Layout.fillWidth: true }
              Text {
                text: card.timeRemainingText
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.colFg ?? "#cdd6f4"
              }
            }

            // Details - Energy
            RowLayout {
              Layout.fillWidth: true
              visible: card.batteryCapacity > 0
              Text {
                text: "Energy"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.colSubtext ?? "#a6adc8"
              }
              Item { Layout.fillWidth: true }
              Text {
                text: card.batteryEnergy.toFixed(1) + " / " + card.batteryCapacity.toFixed(1) + " Wh"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.colFg ?? "#cdd6f4"
              }
            }

            // Details - Health
            RowLayout {
              Layout.fillWidth: true
              visible: card.batteryHealth > 0
              Text {
                text: "Battery Health"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.colSubtext ?? "#a6adc8"
              }
              Item { Layout.fillWidth: true }
              Text {
                text: Math.round(card.batteryHealth * 100) + "%"
                font.pixelSize: Theme.fontSizeSmall
                color: card.batteryHealth >= 0.80 ? (Theme.colFg ?? "#cdd6f4") : "#fab387"
              }
            }

            // Details - Profile
            RowLayout {
              Layout.fillWidth: true
              Layout.topMargin: 2
              Text {
                text: "Power profile"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.colSubtext ?? "#a6adc8"
              }
              Item { Layout.fillWidth: true }
              Text {
                text: {
                  switch(card.activeMode) {
                    case "battery": return "Battery (powersave)"
                    case "auto":
                    case "none": return "Balanced"
                    case "ac": return "AC (performance)"
                    default: return card.activeMode
                  }
                }
                font.pixelSize: Theme.fontSizeSmall
                font.bold: true
                color: Theme.accent1 ?? "#cdd6f4"
              }
            }
          }
        }
      }
    }
  }
}
