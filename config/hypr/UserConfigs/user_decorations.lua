-- ==================================================
--  Theme-aware decorations
-- ==================================================
-- The managed block is kept separate so hypr-omarchy-tool can update it
-- without removing the user's other decoration overrides.

-- BEGIN hypr-omarchy-tool theme
local config_home = os.getenv("XDG_CONFIG_HOME") or ((os.getenv("HOME") or "") .. "/.config")
local decorations = config_home .. "/hypr/lua/hypr_omarchy_decorations.lua"
local ok, err = pcall(dofile, decorations)
if not ok then
  print("[ERROR] hypr-omarchy-tool: unable to load decorations: " .. tostring(err))
end
-- END hypr-omarchy-tool theme
