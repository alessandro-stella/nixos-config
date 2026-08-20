import QtQuick
import "../"

Text {
  id: root
  property int fontSize: Theme.barFontSize

  readonly property var months: [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
  ]

  color: Theme.barColor
  font.pixelSize: root.fontSize 
  font.family: Theme.fontFamily
  font.bold: true
  font.letterSpacing: Theme.letterSpacing

  function updateTime() {
    const now = new Date()
    const hh = String(now.getHours()).padStart(2, "0")
    const mm = String(now.getMinutes()).padStart(2, "0")
    const dd = String(now.getDate()).padStart(2, "0")
    const month = root.months[now.getMonth()]
    const yyyy = now.getFullYear()

    // Format example: 15:35 • 19 Aug 2026
    root.text = `${hh}:${mm} • ${dd} ${month} ${yyyy}`

    // Sync to next minute :00 seconds
    const msUntilNextMinute = (60 - now.getSeconds()) * 1000 - now.getMilliseconds()
    clockTimer.interval = Math.max(500, msUntilNextMinute)
    clockTimer.restart()
  }

  Component.onCompleted: updateTime()

  Timer {
    id: clockTimer
    repeat: false
    onTriggered: root.updateTime()
  }
}
