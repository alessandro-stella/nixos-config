import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../" // Import Theme

Rectangle {
  id: root

  required property PanelWindow parentWindow

  implicitWidth: parent.height 
  implicitHeight: parent.height
  color: "transparent"

  property string notifIcon: "󰂚"
  property bool isDnd: false

  // Listen to swaync status
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
            root.notifIcon = "󰂛";
            root.isDnd = true;
          } else {
            root.notifIcon = "󰂚";
            root.isDnd = false;
          }
        } catch (e) {
          // Ignore parsing error
        }
      }
    }
  }

  // Turn on/off do-not-disturb
  Process {
    id: toggleDnd
    command: ["swaync-client", "-d", "-sw"]
  }

  // Open/close notification panel
  Process {
    id: togglePanel
    command: ["swaync-client", "-t", "-sw"]
  }

  RowLayout {
    id: contentRow
    anchors.centerIn: parent
    spacing: 4

    Text {
      text: root.notifIcon
      font.pixelSize: Theme.barFontSize
      font.family: Theme.fontFamily
      color: root.isDnd ? Theme.colRed : Theme.barColor
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
