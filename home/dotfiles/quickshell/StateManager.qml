pragma Singleton

import QtQuick

QtObject {
    // Popup veri e propri
    property var activePopup: null

    // Widget/modal che devono poter essere chiusi globalmente
    property var activeWidgets: []

    function registerWidget(widget) {
        if (activeWidgets.indexOf(widget) === -1)
            activeWidgets.push(widget)
    }

    function unregisterWidget(widget) {
        const index = activeWidgets.indexOf(widget)

        if (index !== -1)
            activeWidgets.splice(index, 1)
    }

    function requestOpen(popup) {
        if (activePopup !== null && activePopup !== popup)
            activePopup.isOpen = false

        activePopup = popup
        popup.isOpen = true
    }

    function requestClose(popup) {
        if (activePopup === popup)
            activePopup = null

        popup.isOpen = false
    }

    function closeAllWidgets() {
        for (const widget of activeWidgets) {
            if (widget)
                widget.close()
        }
    }

    function closeEverything() {
        // Chiudi popup
        if (activePopup !== null) {
            activePopup.isOpen = false
            activePopup = null
        }

        // Chiudi widget
        for (const widget of activeWidgets) {
            if (widget)
                widget.close()
        }
    }
}
