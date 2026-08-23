import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import "../../"

ColumnLayout {
  id: contentRoot
  spacing: 12

  required property bool useNative
  required property QtObject sysfsBattery
  required property string activeMode
  property var dev: null 

  readonly property real batteryPct: useNative && dev ? dev.percentage : sysfsBattery.percentage
  readonly property real batteryWatts: useNative && dev ? dev.changeRate : sysfsBattery.powerRateW
  readonly property real batteryHealth: useNative && dev && dev.healthSupported ? dev.healthPercentage : (sysfsBattery ? sysfsBattery.health : 0)
  readonly property real batteryEnergy: useNative && dev ? dev.energy : sysfsBattery.energyWh
  readonly property real batteryCapacity: useNative && dev ? dev.energyCapacity : sysfsBattery.energyCapacityWh

  readonly property string statusText: {
    if (useNative && dev) {
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
    if (statusText === "Charging" || statusText === "Fully Charged") return Theme.colGreen;
    if (statusText.indexOf("Threshold Hold") !== -1) return Theme.colBlue;
    if (batteryPct <= 0.15) return Theme.colRed;
    return Theme.barColor
  }

  readonly property string timeRemainingText: {
    let sec = 0;
    if (useNative && dev) {
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

  // Header
  RowLayout {
    Layout.fillWidth: true

    Text {
      text: "Battery"
      font.bold: true
      font.pixelSize: Theme.fontSize
      color: Theme.barColor
      Layout.fillWidth: true
    }

    Text {
      text: contentRoot.statusText
      font.pixelSize: Theme.fontSizeSmall
      font.bold: true
      color: contentRoot.statusColor
    }
  }

  // Percentage + Rate
  RowLayout {
    Layout.fillWidth: true

    Text {
      text: Math.round(contentRoot.batteryPct * 100) + "%"
      font.bold: true
      font.pixelSize: 24
      color: Theme.barColor
    }

    Item { Layout.fillWidth: true }

    Text {
      text: Math.abs(contentRoot.batteryWatts).toFixed(1) + " W"
      font.pixelSize: Theme.fontSizeSmall
      font.bold: true
      color: contentRoot.batteryWatts > 0 ? Theme.colGreen : (contentRoot.batteryWatts < 0 ? Theme.colYellow : (Theme.barDarkColor))
      visible: Math.abs(contentRoot.batteryWatts) > 0
    }
  }

  // Progress Bar
  Rectangle {
    Layout.fillWidth: true
    implicitHeight: 6
    radius: 3
    color: Theme.widgetLightBackground

    Rectangle {
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      width: parent.width * Math.max(0, Math.min(1, contentRoot.batteryPct))
      radius: 3
      color: contentRoot.statusText.indexOf("Threshold Hold") !== -1 ? Theme.colBlue : (contentRoot.batteryPct <= 0.15 ? Theme.colGreen : (contentRoot.batteryPct <= 0.30 ? Theme.colYellow : Theme.colGreen))

      Behavior on width {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
      }
    }
  }

  // Details - Time Remaining
  RowLayout {
    Layout.fillWidth: true
    Text {
      text: (contentRoot.statusText === "Charging") ? "Time to full" : "Remaining time"
      font.pixelSize: Theme.fontSizeSmall
      color: Theme.barDarkColor
    }
    Item { Layout.fillWidth: true }
    Text {
      text: contentRoot.timeRemainingText
      font.pixelSize: Theme.fontSizeSmall
      color: Theme.barColor
    }
  }

  // Details - Energy
  RowLayout {
    Layout.fillWidth: true
    visible: contentRoot.batteryCapacity > 0
    Text {
      text: "Energy"
      font.pixelSize: Theme.fontSizeSmall
      color: Theme.barDarkColor
    }
    Item { Layout.fillWidth: true }
    Text {
      text: contentRoot.batteryEnergy.toFixed(1) + " / " + contentRoot.batteryCapacity.toFixed(1) + " Wh"
      font.pixelSize: Theme.fontSizeSmall
      color: Theme.barColor
    }
  }

  // Details - Health
  RowLayout {
    Layout.fillWidth: true
    visible: contentRoot.batteryHealth > 0
    Text {
      text: "Battery Health"
      font.pixelSize: Theme.fontSizeSmall
      color: Theme.barDarkColor
    }
    Item { Layout.fillWidth: true }
    Text {
      text: Math.round(contentRoot.batteryHealth * 100) + "%"
      font.pixelSize: Theme.fontSizeSmall
      color: contentRoot.batteryHealth >= 0.80 ? (Theme.barColor) : Theme.colYellow 
    }
  }

  // Details - Profile
  RowLayout {
    Layout.fillWidth: true
    Layout.topMargin: 2
    Text {
      text: "Power profile"
      font.pixelSize: Theme.fontSizeSmall
      color: Theme.barDarkColor
    }
    Item { Layout.fillWidth: true }
    Text {
      text: {
        switch(contentRoot.activeMode) {
          case "powersave/BAT": 
            return "Battery (powersave)"
          case "balanced/BAT": 
          case "balanced/AC": 
          case "auto": 
          case "none": 
            return "Balanced"
          case "performance/AC": 
            return "AC (performance)"
          default: 
            return contentRoot.activeMode
        }
      }
      font.pixelSize: Theme.fontSizeSmall
      font.bold: true
      color: Theme.accent1
    }
  }
}
