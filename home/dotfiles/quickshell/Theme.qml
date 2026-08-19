pragma Singleton
import QtQuick

QtObject {
  readonly property color colBg: "#1a1b26"
  readonly property color colFg: "#a9b1d6"
  readonly property color colMuted: "#444b6a"
  readonly property color colCyan: "#0db9d7"
  readonly property color colPurple: "#ad8ee6"
  readonly property color colRed: "#f7768e"
  readonly property color colYellow: "#e0af68"
  readonly property color colBlue: "#7aa2f7"

  readonly property string fontFamily: "JetBrainsMono Nerd Font"
  readonly property int fontSize: 16
  readonly property int fontSizeSmall: 14
  readonly property int barHeight: 30

  readonly property int slowAnimation: 250
  readonly property int fastAnimation: 150

  readonly property int borderWidth: 2
  readonly property int radiusInner: 5
  readonly property int radiusOuter: radiusInner + borderWidth

  readonly property color accent1: "#E7E7EF"
  readonly property color accent2: "#D4D5DF"

  // Width properties
  readonly property real widgetWidthRatio: 0.30
  readonly property int widgetMinWidth: 440
  readonly property int widgetMaxWidth: 640

  // Height properties
  readonly property real widgetHeightRatio: 0.50 
  readonly property int widgetMinHeight: 380
  readonly property int widgetMaxHeight: 520 
  readonly property int widgetDefaultHeight: 480 
}
