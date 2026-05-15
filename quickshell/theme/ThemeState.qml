pragma Singleton
import QtQuick
import Quickshell

Singleton {
    property bool isDark: true

    onIsDarkChanged: {
        const theme = isDark ? "adw-gtk3-dark" : "adw-gtk3"
        const scheme = isDark ? "prefer-dark" : "prefer-light"
        
        Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.interface", "gtk-theme", theme])
        Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.interface", "color-scheme", scheme])

        const tokens = isDark ? "meloworld-tokens-dark.rasi" : "meloworld-tokens-light.rasi"
        Quickshell.execDetached(["/bin/bash", "-c", "ln -sf ~/.config/rofi/themes/" + tokens + " ~/.config/rofi/themes/meloworld-tokens.rasi"])
    }

    Component.onCompleted: {
        // Initialize the symlink on startup
        const tokens = isDark ? "meloworld-tokens-dark.rasi" : "meloworld-tokens-light.rasi"
        Quickshell.execDetached(["/bin/bash", "-c", "ln -sf ~/.config/rofi/themes/" + tokens + " ~/.config/rofi/themes/meloworld-tokens.rasi"])
    }

    function toggleTheme() {
        isDark = !isDark
    }
}
