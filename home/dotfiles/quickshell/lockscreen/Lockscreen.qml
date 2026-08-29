import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland
import Quickshell.Hyprland
import ".."

// Main lock screen window
PanelWindow {
  id: lockWindow
  
  property var modelData 
  required property int monitorId

  property int gracePeriod: 2000

  anchors { top: true; bottom: true; left: true; right: true }
  color: "transparent"
  
  visible: StateManager.isLocked

  // Check if this window is on the active monitor
  function isFocusedMonitor(): bool {
    const monitor = Hyprland.focusedMonitor
    if (!monitor || !lockWindow.screen)
        return false
    return monitor.name === lockWindow.screen.name
  }

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: (visible && isFocusedMonitor()) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  WlrLayershell.namespace: "quickshell-lock"
  exclusionMode: ExclusionMode.Ignore

  // Hyprland submap processes
  Process {
    id: enterSubmap
    command: ["bash", "-c", "hyprctl dispatch 'hl.dsp.submap(\"quickshell-lock\")'"]
  }

  Process {
    id: exitSubmap
    command: ["bash", "-c", "hyprctl dispatch 'hl.dsp.submap(\"reset\")'"]
  }

  onVisibleChanged: {
    if (isFocusedMonitor()) {
      if (visible) enterSubmap.running = true
      else exitSubmap.running = true
    }
  }

  // Load appropriate UI based on monitor focus
  Loader {
    id: mainLoader
    anchors.fill: parent
    active: lockWindow.visible
    sourceComponent: lockWindow.isFocusedMonitor() ? primaryScreenComponent : secondaryScreenComponent
  }

  // Secondary monitor UI
  Component {
    id: secondaryScreenComponent
    Rectangle {
      anchors.fill: parent
      color: Qt.rgba(0, 0, 0, 0.4) 
      
      opacity: StateManager.gracePeriodFinished ? 1 : 0 
      NumberAnimation on opacity {
        from: 0; to: 1
        duration: StateManager.gracePeriodFinished ? 0 : 1000
        easing.type: Easing.InOutQuad
      }

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: (mouse) => { mouse.accepted = true }
      }
    }
  }

  // Primary monitor UI with authentication
  Component {
    id: primaryScreenComponent
    Item {
      anchors.fill: parent
      
      // Authentication state variables
      property string authMode: "parallel"
      property string biometricState: "waiting"
      property string passwordState: "idle"
      property string pwdBuffer: ""
      property bool hasBiometricSensor: false
      property bool isTyping: false

      // Grace period timer
      Timer {
        id: graceTimer
        interval: lockWindow.gracePeriod
        running: !StateManager.gracePeriodFinished
        onTriggered: {
          StateManager.gracePeriodFinished = true
        }
      }

      Timer {
        id: typingTimer
        interval: 350
        onTriggered: isTyping = false
      }

      // Check for available biometric sensors
      Process {
        id: detectBiometricProcess
        command: ["bash", "-c", "fprintd-list $USER 2>/dev/null | grep -q 'has fingerprints' && echo 'available' || echo 'unavailable'"]
        running: true 

        stdout: SplitParser {
          onRead: data => {
            if (data.trim() === "available") {
              hasBiometricSensor = true
              authMode = "parallel"
              fprintProcess.running = true
            } else {
              hasBiometricSensor = false
              authMode = "password_only"
            }
          }
        }
      }

      // Fingerprint verification process
      Process {
        id: fprintProcess
        command: ["fprintd-verify", Quickshell.env("USER")]
        running: false 

        stdout: SplitParser {
          onRead: data => {
            if (!hasBiometricSensor) return;
            
            if (data.includes("verify-match")) {
              biometricState = "matched"
              unlockSystem()
            } else if (data.includes("no match") || data.includes("verify-no-match")) {
              biometricState = "no_match"
              if (StateManager.isLocked) {
                fprintProcess.running = false
                fprintProcess.running = true
              }
            }
          }
        }

        onExited: (code, status) => {
          if (StateManager.isLocked && hasBiometricSensor && !fprintProcess.running) {
            biometricState = "waiting"
            fprintProcess.running = true
          }
        }
      }

      // Password verification via PAM
      PamContext {
        id: pamPassword
        config: "login" 

        onCompleted: (result) => {
          if (result === PamResult.Success) {
            passwordState = "success"
            unlockSystem()
          } else {
            passwordState = "error"
            pwdBuffer = ""
            passwordErrorTimer.start()
          }
        }
      }

      Timer {
        id: passwordErrorTimer
        interval: 1500
        onTriggered: {
          if (StateManager.isLocked) {
            pwdBuffer = ""
            passwordState = "idle"
            if (hasBiometricSensor) biometricState = "waiting"
            if (pamPassword.active) pamPassword.abort()
          }
        }
      }

      // System unlock helper
      function unlockSystem() {
        StateManager.isLocked = false
        StateManager.gracePeriodFinished = false
      }

      Component.onCompleted: {
        keyInterceptor.forceActiveFocus()
      }

      // Keyboard input handling
      Item {
        id: keyInterceptor
        anchors.fill: parent
        focus: true
        Keys.priority: Keys.BeforeItem
        Keys.onPressed: (event) => {
          if (!StateManager.isLocked) return;
          event.accepted = true

          if (!StateManager.gracePeriodFinished) {
            unlockSystem()
            return;
          }

          if (passwordState === "error" || passwordState === "verifying") return;

          if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (pwdBuffer.length > 0) {
              passwordState = "verifying"
              if (!pamPassword.active) pamPassword.start()
              if (pamPassword.responseRequired) pamPassword.respond(pwdBuffer)
            }
          } else if (event.key === Qt.Key_Backspace) {
            pwdBuffer = pwdBuffer.slice(0, -1)
            isTyping = true
            typingTimer.restart()
          } else if (event.key === Qt.Key_Escape) {
            pwdBuffer = ""
            passwordState = "idle"
            if (pamPassword.active) pamPassword.abort()
          } else if (event.text !== "" && event.text.charCodeAt(0) >= 32) {
            pwdBuffer += event.text
            isTyping = true
            typingTimer.restart()
            if (!pamPassword.active && passwordState === "idle") {
              pamPassword.start()
            }
          }
        }
      }

      Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.4) 
        
        opacity: StateManager.gracePeriodFinished ? 1 : 0 
        NumberAnimation on opacity {
          from: 0; to: 1
          duration: StateManager.gracePeriodFinished ? 0 : 1000
          easing.type: Easing.InOutQuad
        }

        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
          onClicked: (mouse) => { mouse.accepted = true }
        }
      }

      // Main authentication UI ring
      Rectangle {
        id: authRing
        anchors.centerIn: parent
        width: 350
        height: 350
        radius: 175
        color: Qt.rgba(0, 0, 0, 0.6)
        
        opacity: StateManager.gracePeriodFinished ? 1 : 0
        scale: StateManager.gracePeriodFinished ? 1 : 0.8
        
        border.width: passwordState === "verifying" ? 0 : Theme.borderWidth * 4
        
        border.color: {
          if (passwordState === "error" || biometricState === "no_match") return Theme.colRed
          if (biometricState === "matched") return Theme.colGreen ?? Theme.accent1
          if (isTyping) return Theme.accent1
          return Theme.colMuted
        }

        // Animazione fluida per i cambi di colore (inclusa l'illuminazione durante la digitazione)
        Behavior on border.color {
          ColorAnimation {
            duration: 250
            easing.type: Easing.InOutQuad
          }
        }

        ParallelAnimation {
          running: !StateManager.gracePeriodFinished 
          
          SequentialAnimation {
            PauseAnimation { duration: lockWindow.gracePeriod * 0.3 } 
            NumberAnimation {
              target: authRing
              property: "opacity"
              from: 0; to: 1
              duration: lockWindow.gracePeriod * 0.7 
              easing.type: Easing.OutCubic
            }
          }
          
          SequentialAnimation {
            PauseAnimation { duration: lockWindow.gracePeriod * 0.3 }
            NumberAnimation {
              target: authRing
              property: "scale"
              from: 0.8; to: 1
              duration: lockWindow.gracePeriod * 0.7
              easing.type: Easing.OutBack
            }
          }
        }

        // Loading spinner animation
        Canvas {
          id: spinnerCanvas
          anchors.fill: parent
          visible: passwordState === "verifying"
          
          onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.beginPath();
            ctx.arc(width/2, height/2, (width/2) - (Theme.borderWidth * 2), 0, Math.PI * 1.75);
            ctx.strokeStyle = Theme.colBlue
            ctx.lineWidth = Theme.borderWidth * 4;
            ctx.lineCap = "round"; 
            ctx.stroke();
          }
          
          RotationAnimation on rotation {
            loops: Animation.Infinite
            from: 0; to: 360
            duration: 1000
            running: spinnerCanvas.visible
          }
        }

        Column {
          anchors.centerIn: parent
          spacing: 15

          Text {
            text: Qt.formatDateTime(new Date(), "hh:mm")
            font.family: Theme.fontFamily
            font.pixelSize: 72
            font.weight: Font.Bold
            color: Theme.colFg
            anchors.horizontalCenter: parent.horizontalCenter
          }

          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10
            height: 20 

            property int maxDots: 10
            
            Repeater {
              model: pwdBuffer.length > 0 ? Math.min(pwdBuffer.length, parent.maxDots) : 0
              Rectangle {
                width: 14; height: 14; radius: 7
                color: Theme.colFg
                anchors.verticalCenter: parent.verticalCenter
              }
            }
          }

          Text {
            visible: hasBiometricSensor && pwdBuffer.length === 0
            text: "󰈷" 
            font.family: Theme.fontFamily
            font.pixelSize: 40
            color: Theme.colFg
            opacity: 0.6
            anchors.horizontalCenter: parent.horizontalCenter
          }
          
          Text {
            visible: passwordState === "error" || biometricState === "no_match" || passwordState === "verifying"
            text: {
              if (passwordState === "verifying") return "Verifying..."
              if (passwordState === "error" || biometricState === "no_match") return "Try again"
              return ""
            }
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            color: (passwordState === "error" || biometricState === "no_match") ? Theme.colRed : Theme.colFg
            anchors.horizontalCenter: parent.horizontalCenter
          }
        }
      }
    }
  }
}
