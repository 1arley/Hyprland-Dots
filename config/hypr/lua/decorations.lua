-- ==================================================
--  KoolDots (2026)
--  Project URL: https://github.com/LinuxBeginnings
--  License: GNU GPLv3
--  SPDX-License-Identifier: GPL-3.0-or-later
-- ==================================================
--
-- Decoration settings for the Lua Hyprland configuration.
-- Colors come from theme_colors.lua, which reads the latest Wallust palette.
-- If Wallust has not generated a palette yet, safe Catppuccin-like fallbacks
-- are used instead of hard-coded theme values.

local config_home = os.getenv("XDG_CONFIG_HOME") or ((os.getenv("HOME") or "") .. "/.config")
local theme_path = config_home .. "/hypr/lua/theme_colors.lua"
local theme = {}
local theme_ok, loaded_theme = pcall(dofile, theme_path)
if theme_ok and type(loaded_theme) == "table" then
  theme = loaded_theme
end

local function color(name, fallback)
  local value = theme[name]
  if type(value) == "string" and value:match("^rgba?%(") then
    return value
  end
  return fallback
end

local active_border = color("color12", "rgba(8db4ffff)")
local inactive_border = color("color10", "rgba(5f6578ff)")
local group_border = color("color15", "rgba(ffffffff)")
local groupbar_active = color("color0", "rgba(0f111aff)")

hl.config({
  general = {
    border_size = 1,
    gaps_in = 4,
    gaps_out = 6,
    col = {
      active_border = active_border,
      inactive_border = inactive_border,
    },
  },
})

hl.config({
  decoration = {
    rounding = 10,
    active_opacity = 1.0,
    inactive_opacity = 0.9,
    fullscreen_opacity = 1.0,
    dim_inactive = true,
    dim_strength = 0.1,
    dim_special = 0.8,
    shadow = {
      enabled = true,
      range = 3,
      render_power = 1,
      color = active_border,
      color_inactive = inactive_border,
    },
    blur = {
      enabled = true,
      size = 6,
      passes = 3,
      new_optimizations = true,
      xray = false,
      ignore_opacity = true,
      special = true,
      popups = true,
    },
  },
})

hl.config({
  group = {
    col = {
      border_active = group_border,
    },
    groupbar = {
      col = {
        active = groupbar_active,
      },
    },
  },
})
