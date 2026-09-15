-- dev-env keybinding overrides for Omarchy 4.
--
-- Loaded by ~/.config/hypr/hyprland.lua via require("hypr.bindings"), after
-- Omarchy's own defaults.
--
-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- macOS muscle memory: Ctrl+Shift+4 starts an interactive region capture.
-- On Omarchy 3.x this ran flameshot; Omarchy 4 has a native capture stack
-- (slurp region picker with keyboard window selection, editor hand-off, OCR)
-- bound to PRINT, so this is the same key pointed at the native tool rather
-- than a second screenshot program.
o.bind("CTRL + SHIFT + 4", "Screenshot (region)", "omarchy-capture-screenshot region")

-- NOT carried over from the 3.x config, because Omarchy 4 already provides it:
--   SUPER + ALT + RETURN -> terminal running `tmux new` in the current
--   directory. See default/hypr/bindings/applications.lua, which binds it to
--   omarchy-launch-terminal-tmux.
