pragma Singleton
import QtQuick
import "./"

QtObject {
  function mix(a, b, t) {
    return Qt.rgba(
      a.r + (b.r - a.r) * t,
      a.g + (b.g - a.g) * t,
      a.b + (b.b - a.b) * t,
      1.0
    )
  }

  readonly property color colBg: Accents.colBg
  readonly property color colFg: Accents.colFg
  readonly property color colMuted: Accents.colMuted

  readonly property color colCyan: "#0db9d7"
  readonly property color colPurple: "#ad8ee6"
  readonly property color colRed: "#f7768e"
  readonly property color colYellow: "#e0af68"
  readonly property color colBlue: "#7aa2f7"
  readonly property color colGreen: "#a6e3a1"
  readonly property color widgetDarkBackground: Accents.widgetDarkBackground
  readonly property color widgetLightBackground: Accents.widgetLightBackground
  readonly property color colRedStrong: "#e92d4d"

  readonly property string fontFamily: "JetBrainsMono Nerd Font Propo"
  readonly property int fontSize: 16
  readonly property int fontSizeSmall: 14
  readonly property real letterSpacing: -0.4

  readonly property int slowAnimation: 250
  readonly property int fastAnimation: 150

  readonly property int outerSpacing: 10
  readonly property int borderWidth: 2
  readonly property int radiusInner: 5
  readonly property int radiusOuter: radiusInner + borderWidth

  readonly property color accent1: Accents.accent1
  readonly property color accent2: Accents.accent2

  // Top bar properties
  readonly property color barBackground: Qt.rgba(colBg.r, colBg.g, colBg.b, 0.3)
  readonly property color barLightBackground: mix(colBg, colFg, 0.777)
  readonly property color barColor: colFg
  readonly property color barDarkColor: mix(colBg, colFg, 0.777)
  readonly property color barMutedColor: mix(colBg, colFg, 0.445)
  readonly property color barWorkspaceHover: Qt.rgba(colFg.r, colFg.g, colFg.b, 0.05)
  readonly property int barHeight: 35
  readonly property int barFontSize: 14
  readonly property int barFontSizeSmall: 11
  readonly property int batteryWarning: 30
  readonly property int batteryCritical: 10
}
