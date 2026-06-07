-- config/animations.lua — meloworld
-- Bezier curves and animation definitions.
-- Motion language: front-loaded, covers distance fast, settles briefly.
-- Weight comes from the landing, not the overall duration.

hl.config({
	animations = {
		enabled = true,
	},
})

-- ─── Bezier Curves ────────────────────────────────────────────────────────────

-- Open: rockets in immediately, very short soft landing at the end
hl.curve("meloOpen", { type = "bezier", points = { { 0.0, 0.85 }, { 0.0, 1.0 } } })

-- Close: instant acceleration out — gone before you think about it
hl.curve("meloClose", { type = "bezier", points = { { 0.55, 0.0 }, { 1.0, 1.0 } } })

-- Move: pure ease-out, very responsive
hl.curve("meloMove", { type = "bezier", points = { { 0.0, 0.0 }, { 0.1, 1.0 } } })

-- Fade: slightly asymmetric — fades in quick, out a touch slower
hl.curve("meloFade", { type = "bezier", points = { { 0.3, 0.0 }, { 0.5, 1.0 } } })

-- Workspace: aggressive ease-out — snaps across, firm landing
hl.curve("meloWorkspace", { type = "bezier", points = { { 0.0, 0.9 }, { 0.1, 1.0 } } })

-- ─── Windows ──────────────────────────────────────────────────────────────────

-- Open: gnomed style — slides in from the top edge, settles. Weighted, not bouncy.
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 2.8, bezier = "meloOpen",  style = "gnomed" })

-- Close: popin to 95% — shrinks away quickly and cleanly.
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 2.0, bezier = "meloClose", style = "popin 95%" })

-- Parent fallback
hl.animation({ leaf = "windows",     enabled = true, speed = 2.8, bezier = "meloOpen" })

-- Move/resize: snappy, grounded
hl.animation({ leaf = "windowsMove", enabled = true, speed = 2.2, bezier = "meloMove" })

-- ─── Fades ────────────────────────────────────────────────────────────────────
hl.animation({ leaf = "fadeIn",     enabled = true, speed = 2.8, bezier = "meloFade" })
hl.animation({ leaf = "fadeOut",    enabled = true, speed = 2.0, bezier = "meloFade" })
hl.animation({ leaf = "fadeSwitch", enabled = true, speed = 2.0, bezier = "meloFade" })
hl.animation({ leaf = "fadeShadow", enabled = true, speed = 2.0, bezier = "meloFade" })
hl.animation({ leaf = "fadeDim",    enabled = true, speed = 2.5, bezier = "meloFade" })
hl.animation({ leaf = "fade",       enabled = true, speed = 2.5, bezier = "meloFade" })

-- ─── Layers ───────────────────────────────────────────────────────────────────
-- Bar, launcher, quickshell panels: slide from edge, land firmly
hl.animation({ leaf = "layersIn",      enabled = true, speed = 2.5, bezier = "meloOpen",  style = "slide" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.8, bezier = "meloClose", style = "slide" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 2.5, bezier = "meloFade" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.8, bezier = "meloFade" })
hl.animation({ leaf = "layers",        enabled = true, speed = 2.5, bezier = "meloOpen" })

-- ─── Workspaces ───────────────────────────────────────────────────────────────
-- slidefade with low percentage = mostly slide, hint of fade.
-- Heavy curve makes it feel like turning a thick page.
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 3.2, bezier = "meloWorkspace", style = "slidefade 10%" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 3.2, bezier = "meloWorkspace", style = "slidefade 10%" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 3.2, bezier = "meloWorkspace", style = "slidefade 10%" })

-- ─── Misc ─────────────────────────────────────────────────────────────────────
-- Border: subtle, slow fade on focus change
hl.animation({ leaf = "border",     enabled = true, speed = 2.0, bezier = "meloFade" })

-- Zoom: kept modest
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 3.0, bezier = "meloOpen" })
