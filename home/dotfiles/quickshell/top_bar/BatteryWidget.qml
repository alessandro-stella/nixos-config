import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import "../"

Rectangle {
  id: root

  required property PanelWindow parentWindow

  visible: isBatteryPresent

  implicitWidth: contentRow.implicitWidth + 16
  implicitHeight: parent.height
  color: "transparent"

  property bool sysfsBatteryExists: false
  
  Process {
    command: ["sh", "-c", "ls -d /sys/class/power_supply/BAT* 2>/dev/null | grep -q . && echo 1 || echo 0"]
    running: true
    stdout: SplitParser {
      onRead: data => {
        if (data.trim() === "1") {
          sysfsBatteryExists = true;
        }
      }
    }
  }

  // Only use UPower if sysfs found a battery
  readonly property var dev: sysfsBatteryExists ? UPower.displayDevice : null
  readonly property bool hasUPower: dev && dev.ready
  
  // Se sysfs non ha batteria, niente UPower
  readonly property bool isBatteryPresent: sysfsBatteryExists

  readonly property int percent: hasUPower ? Math.round(dev.percentage * 100) : 0
  readonly property bool isCharging: hasUPower && dev.state === UPowerDeviceState.Charging
  readonly property bool isAC: hasUPower && (dev.state === UPowerDeviceState.FullyCharged || dev.state === UPowerDeviceState.PendingCharge)

  readonly property string batteryIcon: {
    if (!isBatteryPresent) return "" 

    if (isCharging) {
      if (percent <= 10) return "󰢜"
      if (percent <= 20) return "󰂆"
      if (percent <= 30) return "󰂇"
      if (percent <= 40) return "󰂈"
      if (percent <= 50) return "󰢝"
      if (percent <= 60) return "󰂉"
      if (percent <= 70) return "󰢞"
      if (percent <= 80) return "󰂊"
      if (percent <= 90) return "󰂋"
      return "󰂅"
    }

    if (isAC) return "󰚥"

    if (percent <= 10) return "󰂎"
    if (percent <= 20) return "󰁺"
    if (percent <= 30) return "󰁻"
    if (percent <= 40) return "󰁼"
    if (percent <= 50) return "󰁽"
    if (percent <= 60) return "󰁾"
    if (percent <= 70) return "󰁿"
    if (percent <= 80) return "󰂀"
    if (percent <= 90) return "󰂁"
    return "󰁹"
  }

  readonly property color activeColor: {
    if (isCharging) return Theme.colGreen ?? "#a6e3a1"
    if (isAC) return Theme.colBlue ?? "#89b4fa"
    if (percent <= (Theme.batteryCritical ?? 15)) return Theme.colRed ?? "#f38ba8"
    if (percent <= (Theme.batteryWarning ?? 30)) return Theme.colYellow ?? "#fab387"
    return Theme.barColor
  }

  RowLayout {
    id: contentRow
    anchors.centerIn: parent
    spacing: 4

    Text {
      text: root.batteryIcon
      font.pixelSize: Theme.barFontSize
      font.family: Theme.fontFamily
      color: root.activeColor
    }

    Text {
      text: root.hasUPower ? (root.percent + "%") : ""
      font.pixelSize: Theme.barFontSize
      color: Theme.barColor
      font.family: Theme.fontFamily
      visible: text !== ""
    }
  }

  BatteryPopup {
    id: batteryPopup
    parentWindow: root.parentWindow
    targetItem: root
    sysfsBatteryExists: root.sysfsBatteryExists
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: batteryPopup.toggle()
  }
}
