import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"

Scope {
    id: root

    // Proprietà personalizzabili dall'esterno
    property string ipcTarget: ""
    property string shortcutName: ""
    property alias panelVisible: launcherPanel.visible
    property alias boxWidth: launcherBox.width
    property alias boxHeight: launcherBox.height

    // Tutto ciò che metti dentro <GenericModal> ... </GenericModal> finisce qui dentro
    default property alias content: innerContainer.data

    signal opened()
    signal closed()

    function open(): void {
        launcherPanel.visible = true
        contentWrapper.opacity = 1.0
        root.opened()
    }

    function close(): void {
        contentWrapper.opacity = 0.0
        // Nasconde dopo l'animazione
        closeTimer.start()
        root.closed()
    }

    function toggle(): void {
        if (launcherPanel.visible) {
            close()
        } else {
            open()
        }
    }

    // Gestione IPC
    IpcHandler {
        target: root.ipcTarget
        function toggle(): void {
            if (root.ipcTarget !== "") {
                root.toggle()
            }
        }
    }

    // Gestione Scorciatoia globale
    GlobalShortcut {
        name: root.shortcutName
        onPressed: {
            if (root.shortcutName !== "") {
                root.toggle()
            }
        }
    }

    // Timer per il delay prima di nascondere
    Timer {
        id: closeTimer
        interval: Theme.fastAnimation + 50
        onTriggered: launcherPanel.visible = false
    }

    PanelWindow {
        id: launcherPanel
        screen: Quickshell.focusedScreen
        visible: false
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell-modal"

        exclusionMode: ExclusionMode.Ignore

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        // Wrapper per l'animazione di opacity
        Item {
            id: contentWrapper
            anchors.fill: parent
            opacity: 1.0

            // Animazione smooth per l'opacità
            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.fastAnimation
                    easing.type: Easing.InCubic
                }
            }

            // Sfondo scuro che chiude al click
            MouseArea {
                anchors.fill: parent
                onClicked: root.close()

                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0, 0, 0, 0.5)
                }
            }

            // Box centrale con bordi e stile comune
            Rectangle {
                id: launcherBox
                anchors.centerIn: parent
                width: launcherPanel.screen 
                    ? Math.max(Theme.widgetMinWidth, Math.min(Math.round(launcherPanel.screen.width * Theme.widgetWidthRatio), Theme.widgetMaxWidth)) 
                    : Theme.widgetMaxWidth
                height: Math.min(Theme.widgetDefaultHeight, Theme.widgetMaxHeight)
                radius: Theme.radiusOuter
                color: Theme.colBg
                border.color: Theme.accent1
                border.width: Theme.borderWidth

                // Blocca il click per evitare che il box chiuda se stesso
                MouseArea {
                    anchors.fill: parent
                    onClicked: {}
                }

                Item {
                    id: innerContainer
                    anchors.fill: parent
                    anchors.margins: 16
                }
            }
        }
    }
}
