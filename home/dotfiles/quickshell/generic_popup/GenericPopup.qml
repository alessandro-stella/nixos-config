import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../"

Scope {
    id: genericPopupRoot

    required property Item targetItem
    required property PanelWindow parentWindow
    required property Component contentComponent
    required property real popupWidth

    property bool isOpen: false
    property bool _isLoaded: false

    property real contentHeight: 0

    onIsOpenChanged: {
        if (isOpen && !_isLoaded) {
            _isLoaded = true
        }
    }

    function toggle() {
        isOpen = !isOpen
    }

    Loader {
        id: popupLoader

        active: genericPopupRoot._isLoaded
        sourceComponent: popupInnerComponent
    }

    Component {
        id: popupInnerComponent

        Scope {
            id: innerScope

            Connections {
                target: genericPopupRoot

                function onIsOpenChanged() {
                    if (genericPopupRoot.isOpen) {
                        popup.visible = true
                        card.forceActiveFocus()
                    }
                }
            }

            Component.onCompleted: {
                if (genericPopupRoot.isOpen) {
                    popup.visible = true
                    card.forceActiveFocus()
                }
            }

            PanelWindow {
                id: clickOutsideBackdrop

                screen: genericPopupRoot.parentWindow &&
                        genericPopupRoot.parentWindow.screen
                        ? genericPopupRoot.parentWindow.screen
                        : null

                visible: genericPopupRoot.isOpen &&
                         genericPopupRoot.parentWindow &&
                         genericPopupRoot.parentWindow.screen

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

                    onClicked: {
                        genericPopupRoot.isOpen = false
                    }
                }
            }

            PopupWindow {
                id: popup

                anchor.window: genericPopupRoot.parentWindow
                anchor.item: genericPopupRoot.targetItem

                anchor.edges: Edges.Bottom
                anchor.gravity: Edges.Bottom

                visible: false
                color: "transparent"

                implicitWidth: genericPopupRoot.popupWidth

                // Una sola aggiunta per il padding verticale
                implicitHeight: genericPopupRoot.contentHeight + 28

                Rectangle {
                    id: card

                    anchors.fill: parent

                    color: Theme.colBg
                    radius: Theme.radiusOuter

                    border.color: Theme.accent1
                    border.width: Theme.borderWidth

                    clip: true

                    transformOrigin: Item.Top

                    opacity: genericPopupRoot.isOpen ? 1 : 0
                    scale: genericPopupRoot.isOpen ? 1 : 0.94

                    focus: genericPopupRoot.isOpen

                    Keys.onPressed: (event) => {
                        genericPopupRoot.isOpen = false
                        event.accepted = true
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.slowAnimation
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: Theme.slowAnimation
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.1
                        }
                    }

                    onOpacityChanged: {
                        if (opacity === 0 && !genericPopupRoot.isOpen) {
                            popup.visible = false
                        }
                    }

                    ColumnLayout {
                        id: contentLayout

                        anchors.fill: parent
                        anchors.margins: 14

                        spacing: 12

                        Loader {
                            id: contentLoader

                            Layout.fillWidth: true

                            // IMPORTANTE:
                            // non deve determinare lui l'altezza
                            // del contenuto.
                            Layout.preferredHeight:
                                item ? item.implicitHeight : 0

                            sourceComponent:
                                genericPopupRoot.contentComponent

                            onLoaded: {
                                if (item) {
                                    genericPopupRoot.contentHeight =
                                        item.implicitHeight
                                }
                            }

                            Connections {
                                target: contentLoader.item

                                function onImplicitHeightChanged() {
                                    if (contentLoader.item) {
                                        genericPopupRoot.contentHeight =
                                            contentLoader.item.implicitHeight
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
