import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../"

Scope {
  id: popupScope

  required property Item targetItem
  required property PanelWindow parentWindow
  
  property string connectionType: "disconnected"
  property string ssidName: ""
  property string ipAddress: "N/A"
  property real wifiStrength: 0

  property bool isOpen: false
  property bool _isLoaded: false

  function toggle() {
    if (!isOpen) {
      _isLoaded = true
      StateManager.requestOpen(popupScope)
    } else {
      StateManager.requestClose(popupScope)
    }
  }

  Loader {
    id: popupLoader
    active: popupScope._isLoaded
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
      }
    }
  }

  Component {
    id: popupContentComponent

    GenericPopup {
      id: genericPopup

      parentWindow: popupScope.parentWindow
      targetItem: popupScope.targetItem
      popupWidth: 380

      contentComponent: Item {
        implicitWidth: networkContent.implicitWidth
        implicitHeight: networkContent.implicitHeight

        NetworkPopupContent {
          id: networkContent
          anchors.fill: parent
          connectionType: popupScope.connectionType
          ssidName: popupScope.ssidName
          ipAddress: popupScope.ipAddress
          wifiStrength: popupScope.wifiStrength
        }
      }

      onIsOpenChanged: {
        if (popupScope.isOpen !== isOpen) {
          popupScope.isOpen = isOpen
        }
      }
    }
  }
}
