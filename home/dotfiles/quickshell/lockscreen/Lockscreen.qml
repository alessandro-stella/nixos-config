import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland
import Quickshell.Hyprland
import ".."

PanelWindow {
  id: lockWindow
  
  property var modelData 
  required property var screen
  required property int monitorId

  property int gracePeriod: 2000

  anchors { top: true; bottom: true; left: true; right: true }
  color: "transparent"
  
  visible: StateManager.isLocked

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  WlrLayershell.namespace: "quickshell-lock"
  exclusionMode: ExclusionMode.Ignore

  // Hyprland submap to avoid inputs 
  Process {
    id: enterSubmap
    command: ["bash", "-c", "hyprctl dispatch 'hl.dsp.submap(\"quickshell-lock\")'"]
  }

  Process {
    id: exitSubmap
    command: ["bash", "-c", "hyprctl dispatch 'hl.dsp.submap(\"reset\")'"]
  }

  onVisibleChanged: {
    if (visible) {
      enterSubmap.running = true
    } else {
      exitSubmap.running = true
    }
  }

  // Load widget only when necessary 
  Loader {
    id: mainLoader
    anchors.fill: parent
    active: lockWindow.visible
    
    sourceComponent: Component {
      Item {
        anchors.fill: parent
        
        property string authMode: "parallel"
        property string biometricState: "waiting"
        property string passwordState: "idle"
        property string pwdBuffer: ""
        property bool hasBiometricSensor: false

        // Grace period
        Timer {
          id: graceTimer
          interval: lockWindow.gracePeriod
          running: true 
        }

        // Check for fingerprint reader 
        Process {
          id: detectBiometricProcess
          command: ["bash", "-c", "fprintd-list $USER | grep -q 'has fingerprints' && echo 'available' || echo 'unavailable'"]
          running: lockWindow.monitorId === 0 

          stdout: SplitParser {
            onRead: data => {
              if (data.includes("available")) {
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

        // Fingerprint handling 
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

        // Password handler 
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

        function unlockSystem() {
          StateManager.isLocked = false
        }

        Component.onCompleted: {
          keyInterceptor.forceActiveFocus()
        }

        // Catch keyboard input 
        Item {
          id: keyInterceptor
          anchors.fill: parent
          focus: true
          Keys.priority: Keys.BeforeItem
          Keys.onPressed: (event) => {
            if (!StateManager.isLocked) return;
            event.accepted = true

            if (graceTimer.running) {
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
            } else if (event.key === Qt.Key_Escape) {
              pwdBuffer = ""
              passwordState = "idle"
              if (pamPassword.active) pamPassword.abort()
            } else if (event.text !== "" && event.text.charCodeAt(0) >= 32) {
              pwdBuffer += event.text
              if (!pamPassword.active && passwordState === "idle") {
                pamPassword.start()
              }
            }
          }
        }

        // Design 
        Rectangle {
          anchors.fill: parent
          color: Qt.rgba(0, 0, 0, 0.4) 
          opacity: 0 
          
          // Smooth opacity 
          NumberAnimation on opacity {
            from: 0
            to: 1
            duration: 1000
            easing.type: Easing.InOutQuad
          }

          MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: (mouse) => { mouse.accepted = true }
          }
        }

        Rectangle {
          id: authRing
          anchors.centerIn: parent
          width: 350
          height: 350
          radius: 175
          color: Qt.rgba(0, 0, 0, 0.6)
          
          opacity: 0
          scale: 0.8
          
          border.width: passwordState === "verifying" ? 0 : Theme.borderWidth * 4
          
          border.color: {
            if (passwordState === "error" || biometricState === "no_match") return Theme.colRed
            if (biometricState === "matched") return Theme.colGreen ?? Theme.accent1
            if (pwdBuffer.length > 0) return Theme.accent1
            if (hasBiometricSensor && biometricState === "waiting") return Theme.accent1
            return Theme.colMuted
          }

          // Animation for central circle 
          ParallelAnimation {
            running: true 
            
            SequentialAnimation {
              PauseAnimation { duration: lockWindow.gracePeriod * 0.3 } // Wait for background blur 
              NumberAnimation {
                target: authRing
                property: "opacity"
                from: 0
                to: 1
                duration: lockWindow.gracePeriod * 0.7 // End exactly at grace period
                easing.type: Easing.OutCubic
              }
            }
            
            SequentialAnimation {
              PauseAnimation { duration: lockWindow.gracePeriod * 0.3 }
              NumberAnimation {
                target: authRing
                property: "scale"
                from: 0.8
                to: 1
                duration: lockWindow.gracePeriod * 0.7
                easing.type: Easing.OutBack
              }
            }
          }

          // Animated spinner
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
              from: 0
              to: 360
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
              
              Repeater {
                model: pwdBuffer.length > 0 ? Math.min(pwdBuffer.length, 15) : 0
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
}
