import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../"

PanelWindow {
  id: root

  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Top

  required property int monitorId
  required property var modelData

  screen: modelData

  // --- IMPOSTAZIONI WIDGET ---
  property int currentBrightness: 0
  property int barWidth: 150 
  property int padding: 16 

  // --- IMPOSTAZIONI CICLO DI VITA ---
  property bool isVisible: false
  property int fadeDuration: 200
  property int showDuration: 1000

  anchors {
    top: true
  }

  margins {
    top: Theme.barHeight + Math.round(Theme.outerSpacing / 2) - Math.round(Theme.borderWidth / 2)
  }

  width: layout.implicitWidth + (padding * 2)
  height: layout.implicitHeight + (padding * 2)
  
  color: "transparent"
  readonly property color background: Theme.colBg

  // Inizialmente il popup è spento a livello di sistema
  visible: false

  // --- LOGICA E SHORTCUT ---

  // 1) Calcola le dimensioni esatte della scritta "100%" prima di renderizzarla
  TextMetrics {
    id: percentMetrics
    font.pixelSize: Theme.fontSize
    text: "100%"
  }

  Process {
    id: brightnessProc
    command: ["sh", "-c", "brightnessctl -m | cut -d, -f4 | tr -d '%'"]
    
    stdout: StdioCollector {
      onStreamFinished: {
      console.log("Valore letto:", this.text)
        let val = parseInt(this.text.trim())
        if (!isNaN(val)) {
          root.currentBrightness = val
        }
      }
    }
  } 

  Timer {
    id: displayTimer
    interval: root.showDuration
    onTriggered: {
      root.isVisible = false
      closeTimer.start()
    }
  }

  Timer {
    id: closeTimer
    interval: root.fadeDuration
    onTriggered: {
      root.visible = false
    }
  }

  GlobalShortcut {
    name: "showBrightness"
    onPressed: {
      console.log("Shortcut showBrightness attivata!")
       
      brightnessProc.running = true

      root.visible = true
      root.isVisible = true

      displayTimer.restart()
      closeTimer.stop() 
    }
  }


  Rectangle {
    anchors.fill: parent

    opacity: root.isVisible ? 1.0 : 0.0

    Behavior on opacity {
      NumberAnimation { 
        duration: root.fadeDuration 
        easing.type: Easing.InOutQuad 
      }
    }

    color: Theme.widgetDarkBackground
    radius: Theme.radiusOuter
    
    border.color: Theme.accent1
    border.width: Theme.borderWidth

    RowLayout {
      id: layout
      anchors.centerIn: parent
      spacing: 12

      Text {
        text: "󰃠" 
        font.pixelSize: Theme.fontSize
        color: Theme.barColor        
        Layout.alignment: Qt.AlignVCenter
      }

      Rectangle {
        Layout.preferredWidth: root.barWidth 
        Layout.preferredHeight: 8
        radius: 4
        color: Theme.widgetLightBackground 

        Rectangle {
          width: parent.width * (root.currentBrightness / 100)
          height: parent.height
          radius: parent.radius
          color: Theme.barColor
          
          Behavior on width {
            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
          }
        }
      }

      Text {
        text: root.currentBrightness + "%"
        font.pixelSize: Theme.fontSize
        color: Theme.barColor
        Layout.alignment: Qt.AlignVCenter
        
        Layout.minimumWidth: percentMetrics.width
        Layout.maximumWidth: percentMetrics.width
        horizontalAlignment: Text.AlignRight
      }
    }
  }
}
