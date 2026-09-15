-- dev-env input overrides for Omarchy 4.
--
-- Loaded by ~/.config/hypr/hyprland.lua via require("hypr.input"), after
-- Omarchy's own default/hypr/input.lua. Only the keys that differ from those
-- defaults are set here; everything omitted (follow_mouse, sensitivity,
-- numlock_by_default, repeat_rate 40, touchpad natural_scroll /
-- clickfinger_behavior / scroll_factor 0.4, the DPMS wake settings) already
-- matches what we want.
--
-- See https://wiki.hypr.land/Configuring/Basics/Variables/#input

hl.config({
  input = {
    -- US primary, Brazilian ABNT2 secondary. Left Alt + Right Alt switches.
    -- Omarchy derives the layout from /etc/vconsole.conf instead, which only
    -- ever yields a single layout.
    kb_layout = "us,br",
    kb_variant = ",abnt2",

    -- Caps Lock is Control. This replaces Omarchy's default of
    -- "compose:caps,shift:both_capslock_cancel", so there is no compose key
    -- unless one is added back here.
    kb_options = "ctrl:nocaps,grp:alts_toggle",

    -- Omarchy defaults to 250ms, which fires repeats while still typing.
    repeat_delay = 600,
  },
})

-- Terminal touchpad scroll speeds (Alacritty/kitty/foot 1.5, Ghostty 0.2) are
-- already in Omarchy 4's default input.lua, verbatim. Nothing to add.
