import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../"

Item {
  id: root

  required property PanelWindow parentWindow

  readonly property string iconNormal: "󰂚"
  readonly property string iconDnd: "󰂛"

  property string notifIcon: iconNormal
  property bool isDnd: false

  TextMetrics {
    id: iconDndMetrics
    font.pixelSize: Theme.barFontSize
    font.family: Theme.fontFamily
    text: root.iconDnd 
  }

  TextMetrics {
    id: iconNormalMetrics
    font.pixelSize: Theme.barFontSize
    font.family: Theme.fontFamily
    text: root.iconNormal
  }

  readonly property real maxIconWidth: Math.max(iconDndMetrics.advanceWidth, iconNormalMetrics.advanceWidth)

  implicitWidth: maxIconWidth 
  implicitHeight: parent.height

  // Listen swaync status
  Process {
    id: swayncWatcher
    command: ["swaync-client", "-swb"]
    running: true 
    stdout: SplitParser {
      onRead: data => {
        if (!data) return;
        try {
          let json = JSON.parse(data.trim());
          let altStatus = json.alt || "";
          
          if (altStatus.indexOf("dnd") !== -1) {
            root.notifIcon = root.iconDnd;
            root.isDnd = true;
          } else {
            root.notifIcon = root.iconNormal;
            root.isDnd = false;
          }
        } catch (e) {
          // Ignore parsing errors
        }
      }
    }
  }

  // Toggle DND (left click)
  Process {
    id: toggleDnd
    command: ["swaync-client", "-d", "-sw"]
  }

  // Open/close notification panel (right click)
  Process {
    id: togglePanel
    command: ["swaync-client", "-t", "-sw"]
  }

  RowLayout {
    id: contentRow
    anchors.centerIn: parent
    spacing: 2

    Text {
      text: root.notifIcon
      font.pixelSize: Theme.barFontSize
      font.family: Theme.fontFamily
      color: root.isDnd ? Theme.colRed : Theme.barColor
      
      horizontalAlignment: Text.AlignHCenter 
      Layout.preferredWidth: root.maxIconWidth
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    
    onClicked: (mouse) => {
      if (mouse.button === Qt.LeftButton) {
        toggleDnd.running = true;
      } 
      else if (mouse.button === Qt.RightButton) {
        togglePanel.running = true;
      }
    }
  }
}
