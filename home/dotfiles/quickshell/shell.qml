import Quickshell
import Quickshell.Wayland
import QtQuick

import "./top_bar/"
import "./app_launcher/"
import "./clipboard/"

// ShellRoot {
//   // Top bar
//   Variants {
//     model: Quickshell.screens.length > 0 ? 
//       [...Array(Quickshell.screens.length)].map((_, i) => ({
//         index: i,
//         screen: Quickshell.screens[i]
//       })) : []
//
//     TopBar {
//       monitorId: modelData.index
//       screen: modelData.screen
//     }
//   }
//
//   // App launcher
//   Variants {
//   model: Quickshell.screens.length > 0 ? 
//     [...Array(Quickshell.screens.length)].map((_, i) => ({
//       index: i,
//       screen: Quickshell.screens[i]
//     })) : []
//
//
//   }
//
//   // Clipboard
//   Variants {
//   model: Quickshell.screens.length > 0 ? 
//     [...Array(Quickshell.screens.length)].map((_, i) => ({
//       index: i,
//       screen: Quickshell.screens[i]
//     })) : []
//
//     Clipboard {
//       monitorId: modelData.index
//       screen: modelData.screen
//     }
//   }
// }

ShellRoot {
    id: root
    
    property var monitorModel: Quickshell.screens.length > 0
        ? [...Array(Quickshell.screens.length)].map((_, i) => i)
        : []

    // Top bar
    Variants {
        model: root.monitorModel

        TopBar {
            monitorId: modelData
            screen: Quickshell.screens[modelData]
        }
    }

    // App launcher
    Variants {
        model: root.monitorModel

        AppLauncher {
            monitorId: modelData
            screen: Quickshell.screens[modelData]
        }
    }

    // Clipboard
    Variants {
        model: root.monitorModel

        Clipboard {
            monitorId: modelData
            screen: Quickshell.screens[modelData]
        }
    }
}
