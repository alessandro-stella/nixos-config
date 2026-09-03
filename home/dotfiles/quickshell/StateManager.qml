pragma Singleton
import QtQuick

QtObject {
  // Variables for CreateTheme widget
  property string newThemeImagePath: ""
  property string newThemeColor1: "#000000"
  property string newThemeColor2: "#000000"
  property var newThemePalette: []

  // Variable for lockscreen
  property bool isLocked: false
  property bool gracePeriodFinished: false

  function clearNewThemeState() {
    newThemeImagePath = ""
    newThemeColor1 = "#000000"
    newThemeColor2 = "#000000"
    newThemePalette = []
  }

  // Currently active popup
  property var activePopup: null

  // Currently active widgets
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

  function closeActivePopup() {
    if (activePopup !== null) {
      activePopup.isOpen = false
      activePopup = null
    }
  }

  function closeAllWidgets() {
    for (const widget of activeWidgets)
      if (widget)
        widget.close()

    clearNewThemeState()
  }

  function closeEverything() {
    // Close popup
    if (activePopup !== null) {
      activePopup.isOpen = false
      activePopup = null
    }

    // Close widgets
    for (const widget of activeWidgets) {
      if (widget)
        widget.close()
    }

    clearNewThemeState()
  }

  function toggleLockscreen() {
    isLocked = !isLocked
    if (isLocked) {
      closeEverything()
    }
  }

  // Shared counter for widgets that need Hyprland shortcuts blocked
  property int shortcutBlockCount: 0

  signal shortcutBlockRequested()
  signal shortcutBlockReleased()

  function requestShortcutBlock() {
    shortcutBlockCount++
    if (shortcutBlockCount === 1)
      shortcutBlockRequested()
  }

  function releaseShortcutBlock() {
    shortcutBlockCount = Math.max(0, shortcutBlockCount - 1)
    if (shortcutBlockCount === 0)
      shortcutBlockReleased()
  }
}
