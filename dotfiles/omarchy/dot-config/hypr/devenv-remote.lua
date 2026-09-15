-- -----------------------------------------------------------------------------
-- Hyprland remote/headless configuration - dev-env (Omarchy 4)
--
-- OPT-IN. Nothing loads this by default; `setup-omarchy.sh --remote` appends
--   require("hypr.devenv-remote")
-- to ~/.config/hypr/hyprland.lua. It is for a workstation driven over
-- Sunshine/Moonlight, where the machine may have no physical display at all.
--
-- Dropped from the Omarchy 3.x version of this file, because Omarchy 4 already
-- does it in default/hypr/looknfeel.lua:
--   misc.disable_hyprland_logo, misc.disable_splash_rendering
-- and in default/hypr/bindings/tiling.lua:
--   a special "scratchpad" workspace on SUPER + S / SUPER + ALT + S, which
--   covers what the generic Ctrl+` dropdown here was for.
-- -----------------------------------------------------------------------------

-- Virtual output, so a session comes up and Sunshine has something to capture
-- with no monitor plugged in. A physical monitor, when present, is configured
-- by hypr/monitors.lua and takes precedence.
hl.monitor({ output = "HEADLESS-1", mode = "2560x1440@60", position = "0x0", scale = 1 })

hl.config({
  cursor = {
    -- Keep the cursor on screen: a remote client has no way to wake a hidden one.
    inactive_timeout = 0,
    hide_on_key_press = false,
  },

  input = {
    -- The client already applied its own acceleration curve before sending the
    -- motion; applying a second one here makes the pointer unpredictable.
    accel_profile = "flat",
  },

  misc = {
    -- Variable refresh rate, so the encoder is not pinned to a fixed cadence.
    vrr = 1,
  },
})

-- A dedicated AI-session dropdown, separate from Omarchy's own scratchpad so a
-- long-running agent session is not what you toggle away by reflex.
o.window("scratchpad-claude", { float = true, size = "80% 70%", center = true, opacity = 0.95 })
o.bind("ALT + grave", "Toggle Claude scratchpad", hl.dsp.workspace.toggle_special("claude"))
o.bind(
  "ALT + SHIFT + grave",
  "New Claude scratchpad",
  "[workspace special:claude] ghostty --class=scratchpad-claude"
)
