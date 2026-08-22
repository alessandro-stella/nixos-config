import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

Scope {
  id: popupScope

  required property Item targetItem
  required property PanelWindow parentWindow
  required property Component contentComponent
  required property real popupWidth
  
  property bool isOpen: false
  property bool _isLoaded: false
  property real contentHeight: 0

  function toggle() {
    if (!isOpen) {
      _isLoaded = true
      isOpen = true
    } else {
      isOpen = false
    }
  }

  Loader {
    active: popupScope._isLoaded
    sourceComponent: popupInnerComponent
  }

  Component {
    id: popupInnerComponent
    
    Scope {
      id: innerScope

      Connections {
        target: popupScope
        function onIsOpenChanged() {
          if (popupScope.isOpen) {
            popup.visible = true
            card.forceActiveFocus()
          }
        }
      }

      Component.onCompleted: {
        if (popupScope.isOpen) {
          popup.visible = true
          card.forceActiveFocus()
        }
      }

      // Backdrop to close popup on click
      PanelWindow {
        id: clickOutsideBackdrop
        screen: popupScope.parentWindow.screen
        visible: popupScope.isOpen
        color: "transparent"
        
        anchors {
          top: true
          bottom: true
          left: true
          right: true
        } 
        
        WlrLayershell.layer: WlrLayer.Top

        MouseArea {
          anchors.fill: parent
          onClicked: popupScope.isOpen = false
        }
      }

      // Finestra popup posizionata in alto a destra
      PopupWindow {
        id: popup
        anchor.window: popupScope.parentWindow
        anchor.item: popupScope.targetItem
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom

        visible: false
        color: "transparent"

        implicitWidth: popupScope.popupWidth
        implicitHeight: popupScope.contentHeight + 36

        Rectangle {
          id: card
          anchors.fill: parent
          anchors.topMargin: 5
          color: Theme.colBg ?? "#1e1e2e"
          radius: Theme.radiusOuter
          border.color: Theme.accent1
          border.width: Theme.borderWidth
          clip: true

          transformOrigin: Item.Top
          opacity: popupScope.isOpen ? 1 : 0
          scale: popupScope.isOpen ? 1 : 0.94
          focus: popupScope.isOpen

          Keys.onPressed: (event) => {
            popupScope.isOpen = false;
            event.accepted = true;
          }

          Behavior on opacity {
            NumberAnimation { duration: Theme.slowAnimation; easing.type: Easing.OutCubic }
          }

          Behavior on scale {
            NumberAnimation { duration: Theme.slowAnimation; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
          }

          onOpacityChanged: {
            if (opacity === 0 && !popupScope.isOpen) {
              popup.visible = false;
            }
          }

          // Popup content
          ColumnLayout {
            id: contentLayout
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            Loader {
              id: contentLoader
              Layout.fillWidth: true
              Layout.fillHeight: true
              sourceComponent: popupScope.contentComponent

              onLoaded: {
                if (item && typeof item.implicitHeight !== 'undefined') {
                  popupScope.contentHeight = item.implicitHeight + 24; // Added spacing
                }
              }
            }

            // Update on height change 
            onImplicitHeightChanged: {
              popupScope.contentHeight = implicitHeight + 24;
            }
          }
        }
      }
    }
  }
}
