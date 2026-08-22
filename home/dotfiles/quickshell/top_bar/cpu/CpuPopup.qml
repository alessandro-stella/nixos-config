import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../"
import "../../generic_popup"

Scope {
  id: popupScope

  required property Item targetItem
  required property PanelWindow parentWindow
  
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

  // Carica GenericPopup dinamicamente solo all'apertura
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
      popupWidth: 380 // Un po' più largo per ospitare comodamente Core + RAM
      
      contentComponent: CpuPopupContent {}

      onIsOpenChanged: {
        if (popupScope.isOpen !== isOpen) {
          popupScope.isOpen = isOpen
        }
      }
    }
  } 
}
