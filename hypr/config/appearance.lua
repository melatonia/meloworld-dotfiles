-- config/appearance.lua — meloworld
-- Monitor, general layout settings, decoration, blur, misc.

-- ─── Cursor ───────────────────────────────────────────────────────────────────
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("HYPRCURSOR_SIZE", "22")
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "22")

-- ─── Monitor ──────────────────────────────────────────────────────────────────
hl.monitor({
	output = "",
	mode = "preferred",
	position = "auto",
	scale = "1",
})

-- ─── General + Decoration ─────────────────────────────────────────────────────
hl.config({
	general = {
		gaps_in = 5,
		gaps_out = 10,
		border_size = 4,

		col = {
			active_border = { colors = { "rgba(80cbc4ff)" }, angle = 0 },
			inactive_border = "rgba(37474fff)",
		},

		resize_on_border = true,
		allow_tearing = false,
	},

	decoration = {
		rounding = 8,
		rounding_power = 2,

		active_opacity = 1.0,
		inactive_opacity = 1.0,

		dim_inactive = false,

		shadow = {
			enabled = false,
			range = 10,
			render_power = 3,
			color = "rgba(000000ff)",
		},

		blur = {
			enabled = true,
			size = 8,
			passes = 4,
			noise = 0.02,
			brightness = 0.9,
			contrast = 0.9,
			vibrancy = 0.0,
			new_optimizations = true,
		},
	},

	misc = {
		force_default_wallpaper = 0,
		disable_hyprland_logo = true,
		focus_on_activate = true,
	},
})
