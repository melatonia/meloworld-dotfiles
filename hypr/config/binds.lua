-- config/binds.lua — meloworld
-- All keybindings.
--
-- Modifier logic:
--   SUPER           = window focus / navigation
--   SUPER+SHIFT     = window manipulation (move, state change)
--   SUPER+CTRL      = move window to workspace
--   SUPER+ALT       = layout-level controls (gaps, layout switch)
--   ALT+SHIFT       = monitor focus / window-to-monitor
--   CTRL+SHIFT      = floating window move
--   CTRL+ALT        = floating window resize

local M = "SUPER"

-- ─── Session ──────────────────────────────────────────────────────────────────
hl.bind(M .. " + R", hl.dsp.exec_cmd("hyprctl reload"))
hl.bind(M .. " + SHIFT + Escape", hl.dsp.exit())
hl.bind(M .. " + ALT + L", hl.dsp.exec_cmd("quickshell -c " .. os.getenv("HOME") .. "/.config/quickshell/lockscreen"))

-- ─── Launch ───────────────────────────────────────────────────────────────────
hl.bind("ALT + space", hl.dsp.exec_cmd("qs ipc call launcher toggle"))
hl.bind(M .. " + Return", hl.dsp.exec_cmd("kitty"))
hl.bind(M .. " + E", hl.dsp.exec_cmd("qs ipc call launcher openEmoji"))
hl.bind(M .. " + V", hl.dsp.exec_cmd("qs ipc call launcher openClipboard"))
hl.bind(M .. " + W", hl.dsp.exec_cmd("qs ipc call launcher openWallpaper"))
hl.bind(M .. " + N", hl.dsp.exec_cmd("nautilus"))

-- ─── Window: Lifecycle ────────────────────────────────────────────────────────
hl.bind(M .. " + Q", hl.dsp.window.close())

-- ─── Window: Focus (vi-style hjkl) ───────────────────────────────────────────
hl.bind(M .. " + H", hl.dsp.focus({ direction = "l" }))
hl.bind(M .. " + L", hl.dsp.focus({ direction = "r" }))
hl.bind(M .. " + K", hl.dsp.focus({ direction = "u" }))
hl.bind(M .. " + J", hl.dsp.focus({ direction = "d" }))

-- ─── Window: Overview & Cycle Stack ──────────────────────────────────────────
hl.bind(M .. " + Tab", hl.dsp.workspace.toggle_special("overview"))
hl.bind(M .. " + SHIFT + Tab", hl.dsp.layout("cyclenext"))

-- ─── Window: Swap ─────────────────────────────────────────────────────────────
hl.bind(M .. " + SHIFT + H", hl.dsp.window.swap({ direction = "l" }))
hl.bind(M .. " + SHIFT + J", hl.dsp.window.swap({ direction = "d" }))
hl.bind(M .. " + SHIFT + K", hl.dsp.window.swap({ direction = "u" }))
hl.bind(M .. " + SHIFT + L", hl.dsp.window.swap({ direction = "r" }))

-- ─── Window: State ────────────────────────────────────────────────────────────
hl.bind(M .. " + space", hl.dsp.window.float({ action = "toggle" }))
hl.bind(M .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(M .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
hl.bind(M .. " + comma", hl.dsp.window.move({ workspace = "special:minimized" }))
hl.bind(M .. " + SHIFT + comma", hl.dsp.workspace.toggle_special("minimized"))
hl.bind(M .. " + grave", hl.dsp.workspace.toggle_special("scratchpad"))
hl.bind(M .. " + SHIFT + grave", hl.dsp.window.move({ workspace = "special:scratchpad" }))

-- ─── Layout ───────────────────────────────────────────────────────────────────
do
	local layouts = { "master", "dwindle" }
	local idx = 1
	hl.bind(M .. " + ALT + space", function()
		idx = (idx % #layouts) + 1
		hl.dispatch(hl.dsp.exec_cmd("hyprctl keyword general:layout " .. layouts[idx]))
	end)
end

-- ─── Gaps ─────────────────────────────────────────────────────────────────────
hl.bind(M .. " + ALT + equal", function()
	local g = hl.get_config("general.gaps_in") + 1
	hl.dispatch(hl.dsp.exec_cmd("hyprctl keyword general:gaps_in " .. g))
	hl.dispatch(hl.dsp.exec_cmd("hyprctl keyword general:gaps_out " .. (g * 2)))
end)
hl.bind(M .. " + ALT + minus", function()
	local g = math.max(0, hl.get_config("general.gaps_in") - 1)
	hl.dispatch(hl.dsp.exec_cmd("hyprctl keyword general:gaps_in " .. g))
	hl.dispatch(hl.dsp.exec_cmd("hyprctl keyword general:gaps_out " .. (g * 2)))
end)
hl.bind(M .. " + ALT + G", function()
	local g = hl.get_config("general.gaps_in")
	if g > 0 then
		hl.dispatch(hl.dsp.exec_cmd("hyprctl keyword general:gaps_in 0"))
		hl.dispatch(hl.dsp.exec_cmd("hyprctl keyword general:gaps_out 0"))
	else
		hl.dispatch(hl.dsp.exec_cmd("hyprctl keyword general:gaps_in 5"))
		hl.dispatch(hl.dsp.exec_cmd("hyprctl keyword general:gaps_out 10"))
	end
end)

-- ─── Workspaces: Switch ───────────────────────────────────────────────────────
hl.bind(M .. " + left", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(M .. " + right", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(M .. " + CTRL + left", hl.dsp.window.move({ workspace = "e-1" }))
hl.bind(M .. " + CTRL + right", hl.dsp.window.move({ workspace = "e+1" }))

for i = 1, 9 do
	hl.bind(M .. " + " .. i, hl.dsp.focus({ workspace = i }))
	hl.bind(M .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end

-- ─── Monitor: Focus / Move ────────────────────────────────────────────────────
hl.bind("ALT + SHIFT + left", hl.dsp.focus({ monitor = "l" }))
hl.bind("ALT + SHIFT + right", hl.dsp.focus({ monitor = "r" }))
hl.bind(M .. " + ALT + left", hl.dsp.window.move({ monitor = "l" }))
hl.bind(M .. " + ALT + right", hl.dsp.window.move({ monitor = "r" }))

-- ─── Window: Move (Floating) ──────────────────────────────────────────────────
hl.bind("CTRL + SHIFT + up", hl.dsp.window.move({ x = 0, y = -20, relative = true }), { repeating = true })
hl.bind("CTRL + SHIFT + down", hl.dsp.window.move({ x = 0, y = 20, relative = true }), { repeating = true })
hl.bind("CTRL + SHIFT + left", hl.dsp.window.move({ x = -20, y = 0, relative = true }), { repeating = true })
hl.bind("CTRL + SHIFT + right", hl.dsp.window.move({ x = 20, y = 0, relative = true }), { repeating = true })

-- ─── Window: Resize ───────────────────────────────────────────────────────────
hl.bind("CTRL + ALT + up", hl.dsp.window.resize({ x = 0, y = -20, relative = true }), { repeating = true })
hl.bind("CTRL + ALT + down", hl.dsp.window.resize({ x = 0, y = 20, relative = true }), { repeating = true })
hl.bind("CTRL + ALT + left", hl.dsp.window.resize({ x = -20, y = 0, relative = true }), { repeating = true })
hl.bind("CTRL + ALT + right", hl.dsp.window.resize({ x = 20, y = 0, relative = true }), { repeating = true })

-- ─── Mouse: Move / Resize ─────────────────────────────────────────────────────
hl.bind(M .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(M .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ─── Scroll: Workspace Navigation ────────────────────────────────────────────
hl.bind(M .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(M .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- ─── Media & Hardware Keys ────────────────────────────────────────────────────
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ --limit 1.0"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
	{ locked = true, repeating = true }
)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { locked = true, repeating = true })

-- ─── Media Controls ───────────────────────────────────────────────────────────
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- ─── Screenshot ───────────────────────────────────────────────────────────────
hl.bind(M .. " + SHIFT + S", hl.dsp.exec_cmd("sh -c 'grim /tmp/qs-master.png; qs ipc call screenshot capture'"))
