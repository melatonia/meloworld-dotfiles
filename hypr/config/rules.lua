-- config/rules.lua — meloworld
-- Window rules and layer rules.

-- Set this for smooth nvidia experience
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")

-- ─── Window Rules ─────────────────────────────────────────────────────────────
hl.window_rule({
	match = { title = "nmtui" },
	float = true,
	size = { 600, 400 },
})

hl.window_rule({
	match = { class = "com.mitchellh.kitty" },
	float = true,
	size = { 860, 600 },
})

hl.window_rule({
	match = { class = "Spotify" },
	float = true,
	size = { 1600, 900 },
})

hl.window_rule({
	match = { class = "org.gnome.Nautilus" },
	float = true,
	size = { 900, 600 },
})

hl.window_rule({
	match = { title = "Vesktop" },
	float = true,
	size = { 1400, 860 },
})

-- Suppress maximize requests globally
hl.window_rule({
	name = "suppress-maximize",
	match = { class = ".*" },
	suppress_event = "maximize",
})

-- Fix XWayland floating drag issues
hl.window_rule({
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},
	no_focus = true,
})

-- ─── Layer Rules ──────────────────────────────────────────────────────────────
hl.layer_rule({
	match = { namespace = "selection" },
	blur = false,
	no_anim = true,
})

hl.layer_rule({
	match = { namespace = "qs-screenshot" },
	animation = "fade",
})

hl.layer_rule({
	match = { namespace = "polkit-dialog" },
	blur = false,
})

hl.layer_rule({
	match = { namespace = "qs-idle-overlay" },
	blur = true,
})
