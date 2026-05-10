pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"

Singleton {
    id: root

    property real cpuUsage: 0
    property real ramUsage: 0
    property real gpuUsage: 0

    Process {
        id: statsProc
        running: SessionState.dashboardVisible
        // Using ~/.config/mango/scripts/ since this is where the dots are usually deployed.
        command: ["bash", "-c", "if [ -x ~/.config/mango/scripts/stats-daemon.sh ]; then ~/.config/mango/scripts/stats-daemon.sh; elif [ -x ~/Projects/rice/meloworld-dotfiles/mango/scripts/stats-daemon.sh ]; then ~/Projects/rice/meloworld-dotfiles/mango/scripts/stats-daemon.sh; else echo '0 0 0'; sleep 2; fi"]
        stdout: SplitParser {
            onRead: (line) => {
                let parts = line.trim().split(" ")
                if (parts.length >= 3) {
                    root.cpuUsage = Math.min(100, Math.max(0, parseInt(parts[0]) || 0))
                    root.ramUsage = Math.min(100, Math.max(0, parseInt(parts[1]) || 0))
                    
                    let rawGpu = parseInt(parts[2]) || 0
                    let smoothVal = (rawGpu * 0.2) + (root.gpuUsage * 0.8)
                    root.gpuUsage = Math.min(100, Math.max(0, smoothVal))
                }
            }
        }
    }
}
