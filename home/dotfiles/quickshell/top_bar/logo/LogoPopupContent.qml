import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../"

Item {
  id: contentRoot

  implicitWidth: 380
  implicitHeight: Math.min(mainLayout.implicitHeight, (parentWindow ? parentWindow.screen.height / 2 : 600) - 40)

  property bool isOpen: false
  
  signal requestClose()
  
  property int totalPackages: 0
  property int checkedPackages: 0
  property int outdatedCount: 0
  property bool isChecking: false
  
  property var startTime: 0
  property int elapsedTime: 0

  ListModel {
    id: updatesModel
  }

  onIsOpenChanged: {
    if (isOpen) {
      refresh()
    }
  }

  Component.onDestruction: {
    if (checkUpdatesProcess.running) {
      checkUpdatesProcess.running = false
    }
  }

  function refresh() {
    if (isChecking) return;
    
    updatesModel.clear()
    checkedPackages = 0
    totalPackages = 0
    outdatedCount = 0
    elapsedTime = 0
    startTime = Date.now()
    isChecking = true
    checkUpdatesProcess.running = true
  }

  Component.onCompleted: refresh()

  Process {
    id: checkUpdatesProcess
    command: ["zsh", "-i", "-c", "~/.config/quickshell/top_bar/logo/check-updates.sh"]

    stdout: SplitParser {
      onRead: data => {
        if (!data || data.trim() === "") return;
        
        let parts = data.trim().split("|")
        
        if (parts[0] === "TOTAL") {
          contentRoot.totalPackages = parseInt(parts[1]) || 0
        } else if (parts[0] === "PROGRESS") {
          contentRoot.checkedPackages = parseInt(parts[1])
        } else if (parts[0] === "DONE") {
          contentRoot.outdatedCount = parseInt(parts[1])
          contentRoot.elapsedTime = Math.round((Date.now() - contentRoot.startTime) / 1000)
        } else if (parts[0] === "RESULT") {
          let jsonString = parts.slice(1).join("|")
          let updates = JSON.parse(jsonString)
          
          for (let i = 0; i < updates.length; i++) {
            updatesModel.append(updates[i])
          }
          contentRoot.isChecking = false
        }
      }
    }
    
    onExited: contentRoot.isChecking = false
  }

  Process {
    id: openTerminalProcess
    command: ["foot", "zsh", "-i", "-c", "cd ~/nixos-config && nixos-apply --update; echo '\nPress Enter to close...'; read"]
  }

  ColumnLayout {
    id: mainLayout
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    spacing: 16

    RowLayout {
      Layout.fillWidth: true
      
      Text {
        text: "NixOS Updates"
        font.bold: true
        font.pixelSize: Theme.fontSize
        color: Theme.barColor
        Layout.fillWidth: true
      }
      
      Rectangle {
        width: updateText.implicitWidth + 24
        height: 26
        radius: 13
        color: Theme.colBlue
        visible: !contentRoot.isChecking && contentRoot.outdatedCount > 0
        
        Text {
          id: updateText
          anchors.centerIn: parent
          text: " Update"
          font.pixelSize: Theme.fontSizeSmall
          color: Theme.widgetLightBackground
          font.bold: true
        }
        
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            contentRoot.requestClose()
            openTerminalProcess.running = true
          }
        }
      }
      
      Rectangle {
        width: 26
        height: 26
        radius: 13
        color: Theme.widgetLightBackground
        
        Text {
          anchors.centerIn: parent
          text: ""
          font.pixelSize: Theme.fontSizeSmall
          color: Theme.barColor
          
          RotationAnimation on rotation {
            loops: Animation.Infinite
            from: 0
            to: 360
            duration: 1000
            running: contentRoot.isChecking
          }
        }
        
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: contentRoot.refresh()
        }
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      visible: contentRoot.isChecking
      spacing: 6
      
      Text {
        text: contentRoot.totalPackages === 0 
            ? "Fetching local packages..." 
            : "Checking: " + contentRoot.checkedPackages + " / " + contentRoot.totalPackages
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
          width: contentRoot.totalPackages === 0 ? 0 : parent.width * (contentRoot.checkedPackages / Math.max(1, contentRoot.totalPackages))
          radius: 3
          color: Theme.colBlue
          
          Behavior on width {
            NumberAnimation {
              duration: 250
              easing.type: Easing.OutCubic
            }
          }
        }
      }
    }

    Text {
      visible: !contentRoot.isChecking
      text: contentRoot.outdatedCount > 0 
            ? "Found " + contentRoot.outdatedCount + " updates in " + contentRoot.elapsedTime + "s:"
            : "System is up to date!"
      font.pixelSize: Theme.fontSizeSmall
      color: contentRoot.outdatedCount > 0 ? Theme.colYellow : Theme.colGreen
      font.bold: true
    }

    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: Math.min(updatesModel.count * 36, (parentWindow ? parentWindow.screen.height / 2 : 500) - 120)
      color: "transparent"
      visible: updatesModel.count > 0
      clip: true

      ListView {
        anchors.fill: parent
        model: updatesModel
        spacing: 6
        
        delegate: Rectangle {
          width: ListView.view.width
          height: 30
          color: Theme.widgetLightBackground
          radius: 4
          
          RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8
            
            Text {
              text: model.name
              font.bold: true
              font.pixelSize: Theme.fontSizeSmall
              color: Theme.barColor
              Layout.fillWidth: true
              Layout.minimumWidth: 80
              elide: Text.ElideRight
            }
            
            Text {
              text: model.oldVersion + " → " + model.newVersion
              font.pixelSize: Theme.fontSizeSmall
              color: Theme.barDarkColor
              Layout.maximumWidth: 180
              elide: Text.ElideRight
              horizontalAlignment: Text.AlignRight
            }
          }
        }
      }
    }
  }
}
