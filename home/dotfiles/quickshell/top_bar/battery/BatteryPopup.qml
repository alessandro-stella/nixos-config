import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import "../"
import "../../generic_popup"

Scope {
  id: popupScope

  required property Item targetItem
  required property PanelWindow parentWindow
  required property bool sysfsBatteryExists
  
  property bool isOpen: false
  property bool _isLoaded: false
  property string tlpMode: "auto"

  function toggle() {
    if (!isOpen) {
      _isLoaded = true
      isOpen = true
    } else {
      isOpen = false
    }
  }

  // Battery data container
  QtObject {
    id: sysfsBatteryData
    property real percentage: 0.0
    property string rawStatus: "Unknown"
    property real timeRemaining: 0
    property real powerRateW: 0
    property real energyWh: 0
    property real energyCapacityWh: 0
    property real health: 1.0
  }

  // Timer for sysfs polling
  Timer {
    id: batteryPoller
    interval: 4000
    running: popupScope.isOpen && !popupScope.useNative
    repeat: true
    onTriggered: readSysfs.running = true
  }

  // Read sysfs battery
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

  // UPower device
  readonly property var dev: sysfsBatteryExists && UPower.displayDevice ? UPower.displayDevice : null
  readonly property bool useNative: dev && dev.ready

  // Dynamically load GenericPopup
  Loader {
    id: popupLoader
    active: popupScope._isLoaded && popupScope.sysfsBatteryExists
    sourceComponent: popupContentComponent

    onLoaded: {
      if (item) {
        item.isOpen = popupScope.isOpen
      }
    }
  }

  Connections {
    target: popupScope
    function onIsOpenChanged() {
      if (popupLoader.item && popupLoader.item.isOpen !== popupScope.isOpen) {
        popupLoader.item.isOpen = popupScope.isOpen
        if (popupScope.isOpen) {
          getTlpMode.running = true
        }
      }
    }
  }

  Component {
    id: popupContentComponent

    GenericPopup {
      id: genericPopup
      
      parentWindow: popupScope.parentWindow
      targetItem: popupScope.targetItem
      popupWidth: 300
      
      contentComponent: BatteryPopupContent {
        useNative: popupScope.useNative
        sysfsBattery: sysfsBatteryData
        dev: popupScope.dev
        activeMode: popupScope.tlpMode
      }

      onIsOpenChanged: {
        if (popupScope.isOpen !== isOpen) {
          popupScope.isOpen = isOpen
        }
      }
    }
  } 

  // Read TLP mode
  Process {
    id: getTlpMode
    command: ["sh", "-c", "tlp-stat -s 2>/dev/null | awk '/Power profile/ {print $4}' || echo 'auto'"]
    running: false 
    stdout: SplitParser {
      onRead: data => {
        if (data && data.trim() !== "") {
          popupScope.tlpMode = data.trim();
        }
      }
    }
  }
}
