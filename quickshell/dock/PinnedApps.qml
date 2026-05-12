pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property var apps: [
        { id: "zen-browser",        label: "Zen",     icon: "zen-browser"         },
        { id: "zed",                label: "Zed",     icon: "zed"                 },
        { id: "spotify",            label: "Spotify", icon: "spotify"             },
        { id: "org.gnome.Nautilus", label: "Files",   icon: "system-file-manager" }
    ]
}
