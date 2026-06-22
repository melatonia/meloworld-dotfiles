-- config/autostart.lua — meloworld
-- Commands to run on Hyprland startup.

hl.on("hyprland.start", function()
	hl.exec_cmd("dbus-update-activation-environment --systemd --all")
	hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/wallpaper-restore.sh")
	hl.exec_cmd("quickshell")
	hl.exec_cmd("wl-paste --type text  --watch cliphist store")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")
	hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/nightlight.sh")
	hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/chime.sh")
	hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/usb-sound.sh")
	--  hl.exec_cmd(
	--		"sh -c 'sleep 5 && env ELECTRON_OZONE_PLATFORM_HINT=auto /usr/lib/electron40/electron /usr/lib/vesktop/app.asar --start-minimized'"
	--	)
	hl.exec_cmd("hypridle")
end)
hl.on("hyprland.shutdown", function()
	os.execute("systemctl --user stop hyprland-session.target && sleep 0.1")
end)
