-- Dynamic Wallust colors for the Lua Hyprland configuration.
-- The file is intentionally a runtime reader rather than a generated snapshot:
-- ThemeChanger.sh and WallustSwww.sh already regenerate wallust-hyprland.conf
-- and reload Hyprland, so the next reload always picks up the newest palette.

local config_home = os.getenv("XDG_CONFIG_HOME") or ((os.getenv("HOME") or "") .. "/.config")
local theme_file = config_home .. "/hypr/wallust/wallust-hyprland.conf"

local colors = {
  background = "rgba(090300ff)",
  foreground = "rgba(a5a2a2ff)",
  color0 = "rgba(090300ff)",
  color1 = "rgba(db2d20ff)",
  color2 = "rgba(01a252ff)",
  color3 = "rgba(fded02ff)",
  color4 = "rgba(01a0e4ff)",
  color5 = "rgba(a16a94ff)",
  color6 = "rgba(b5e4f4ff)",
  color7 = "rgba(a5a2a2ff)",
  color8 = "rgba(5c5855ff)",
  color9 = "rgba(e8bbd0ff)",
  color10 = "rgba(3a3432ff)",
  color11 = "rgba(4a4543ff)",
  color12 = "rgba(807d7cff)",
  color13 = "rgba(d6d5d4ff)",
  color14 = "rgba(cdab53ff)",
  color15 = "rgba(f7f7f7ff)",
}

local function trim(value)
  return (value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function normalize(value, fallback)
  value = trim(value):gsub("%s+#.*$", "")
  local hex = value:match("^#(%x+)$") or value:match("^(%x+)$")
  if not hex then
    hex = value:match("^rgba%(%s*(%x+)%s*%)")
  end
  if not hex then
    hex = value:match("^rgb%(%s*(%x+)%s*%)")
  end
  if not hex then
    return fallback
  end

  hex = hex:lower()
  if #hex == 3 then
    hex = hex:sub(1, 1):rep(2) .. hex:sub(2, 2):rep(2) .. hex:sub(3, 3):rep(2)
  elseif #hex == 6 then
    hex = hex .. "ff"
  elseif #hex ~= 8 then
    return fallback
  end
  return "rgba(" .. hex .. ")"
end

local handle = io.open(theme_file, "r")
if handle then
  for line in handle:lines() do
    local name, value = line:match("^%s*%$([%w_]+)%s*=%s*(.-)%s*$")
    if name and colors[name] then
      colors[name] = normalize(value, colors[name])
    end
  end
  handle:close()
end

return colors
