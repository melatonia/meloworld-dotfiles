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

    Timer {
        interval: 2500
        running: SessionState.dashboardVisible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            cpuProc.running = true
            ramProc.running = true
            gpuProc.running = true
        }
    }

    Process {
        id: cpuProc
        command: ["bash", "-c", "top -bn1 | grep 'Cpu(s)' | awk '{print $2+$4+$6}'"]
        stdout: StdioCollector {
            onStreamFinished: root.cpuUsage = Math.min(100, Math.max(0, parseFloat(text.trim()) || 0))
        }
    }

    Process {
        id: ramProc
        command: ["bash", "-c", "free | grep Mem | awk '{print $3/$2 * 100.0}'"]
        stdout: StdioCollector {
            onStreamFinished: root.ramUsage = Math.min(100, Math.max(0, parseFloat(text.trim()) || 0))
        }
    }

    Process {
        id: gpuProc
        // The error was likely a missing comma or unescaped quote in this long command string
        command: ["bash", "-c", "cat /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null | head -n 1 || nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null || echo 0"]
        stdout: StdioCollector {
            onStreamFinished: {
                let val = parseFloat(text.trim());
                root.gpuUsage = isNaN(val) ? 0 : Math.min(100, Math.max(0, val));
            }
        }
    }
}
