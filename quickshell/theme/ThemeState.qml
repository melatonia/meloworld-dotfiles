pragma Singleton
import QtQuick
import Qt.labs.settings
import Quickshell

Singleton {
    id: root
    property bool isDark: true

    Settings {
        category: "Theme"
        property alias isDark: root.isDark
    }

    function sync() {
        const theme = isDark ? "adw-gtk3-dark" : "adw-gtk3"
        const scheme = isDark ? "prefer-dark" : "prefer-light"
        
        Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.interface", "gtk-theme", theme])
        Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.interface", "color-scheme", scheme])

        const tokens = isDark ? "meloworld-tokens-dark.rasi" : "meloworld-tokens-light.rasi"
        Quickshell.execDetached(["/bin/bash", "-c", "ln -sf ~/.config/rofi/themes/" + tokens + " ~/.config/rofi/themes/meloworld-tokens.rasi"])
    }

    onIsDarkChanged: sync()

    Component.onCompleted: {
        // Initialize the theme and symlinks on startup
        sync()
    }

    function toggleTheme() {
        isDark = !isDark
    }
}
