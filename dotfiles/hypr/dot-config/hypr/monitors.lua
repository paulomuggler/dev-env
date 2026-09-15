-- dev-env monitor layout for Omarchy 4.
--
-- Loaded by ~/.config/hypr/hyprland.lua via require("hypr.monitors").
-- List current monitors and supported resolutions with: hyprctl monitors all
--
-- The catch-all below is Omarchy's own default and must stay first: it gives
-- any monitor we have not named a preferred mode, an automatic position and an
-- automatic scale. Named monitors after it win.

local omarchy_gdk_scale = 2
local omarchy_monitor_scale = "auto"

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- LG 27GN950 4K. Matched by description rather than connector, because the
-- connector name is GPU-dependent: this panel is DP-12 on the old machine and
-- DP-10 on this one, and a different port would rename it again.
hl.monitor({
  output = "desc:LG Electronics 27GN950 204NTWG6W465",
  mode = "3840x2160@60",
  position = "auto",
  scale = 1.5,
})

-- The 2560x1440@144 panel that sat to the left of the 4K on the old machine
-- (DP-1 there, at 0x0 with scale 1.0) is not connected to this machine yet, so
-- neither its connector name nor its description is known here. Until it is,
-- the catch-all above gives it a preferred mode at an automatic position.
-- To restore the old side-by-side layout, fill in its description and pin both:
--   hl.monitor({ output = "desc:<make model serial>", mode = "2560x1440@144", position = "0x0", scale = 1 })
--   and change the 4K's position above to "2560x0".
