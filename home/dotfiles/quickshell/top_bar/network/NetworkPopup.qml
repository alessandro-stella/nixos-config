import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../"

Scope {
  id: popupScope

  required property Item targetItem
  required property PanelWindow parentWindow

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

      contentComponent: NetworkPopupContent {}

      onIsOpenChanged: {
        if (popupScope.isOpen !== isOpen) {
          popupScope.isOpen = isOpen
        }
      }
    }
  }
}
