-- config/input.lua — meloworld
-- Keyboard, mouse, and touchpad settings.
-- Note: env vars (XCURSOR_THEME, XCURSOR_SIZE, HYPRCURSOR_SIZE)
-- belong in ~/.config/uwsm/env, not here.

hl.config({
	input = {
		kb_layout = "tr",
		kb_variant = "",
		kb_model = "",
		kb_options = "caps:escape",
		kb_rules = "",

		repeat_rate = 40,
		repeat_delay = 400,

		numlock_by_default = true,

		follow_mouse = 1,
		mouse_refocus = true,

		sensitivity = -0.4,
		accel_profile = "flat",
		natural_scroll = false,

		touchpad = {
			natural_scroll = true,
			disable_while_typing = true,
			tap_to_click = true,
			drag_lock = true,
			clickfinger_behavior = false,
			middle_button_emulation = false,
		},
	},
	cursor = {
		no_warps = true,
	},
})
