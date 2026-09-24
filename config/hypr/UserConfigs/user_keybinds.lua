-- User keybind overrides.
-- Add, override, or rebind keybinds here.
--
-- =============================================================================
-- KEYBIND RULES & SYNTAX
-- =============================================================================
-- • bind("MODS", "KEY", action, [options])
-- • unbind("MODS", "KEY")
--
-- Supported modifiers:
--   "SUPER", "SHIFT", "CTRL", "ALT", or combinations like "SUPER SHIFT", "SUPER ALT"
--
-- Actions:
--   • exec_cmd("command")       -> launches a terminal command or script
--   • dispatch("dispatcher", [arg]) -> triggers a Hyprland dispatcher (e.g. killactive, togglefloating)
--
-- =============================================================================
-- EXAMPLES
-- =============================================================================
--
-- NOTE ON LUA REBINDS:
--   Yes — same rule as Hyprlang applies in practice: if a key combo is already bound,
--   unbind("MODS", "KEY") first, then bind(...) it to the new action.
--   This keeps behavior explicit and avoids duplicate/conflicting binds.
--
-- 1. ADDING A BRAND NEW KEYBIND (combo not used by default):
--    bind("SUPER", "Z", exec_cmd("ghostty"), { description = "Launch Ghostty" })
--    bind("SUPER SHIFT", "V", exec_cmd("pavucontrol"), { description = "Audio Control" })
--    bind("SUPER", "X", dispatch("killactive"), { description = "Close active window" })
--
-- 2. OVERRIDING AN EXISTING COMBO WITH A DIFFERENT APP/COMMAND:
--    -- To replace what SUPER+Return opens (default: kitty):
--    unbind("SUPER", "Return")
--    bind("SUPER", "Return", exec_cmd("ghostty"), { description = "Launch Ghostty" })
--
-- 3. REBINDING / MOVING AN ACTION TO A NEW KEY COMBINATION:
--    -- Example: Move File Manager from SUPER+E to SUPER+F, and use SUPER+E for Emacs:
--    unbind("SUPER", "E")       -- unbind default file manager from SUPER+E
--    unbind("SUPER", "F")       -- unbind whatever SUPER+F was doing (default: fake fullscreen)
--    bind("SUPER", "F", exec_cmd("$HOME/.config/hypr/scripts/LaunchFileManager.sh '$files' '$term'"), { description = "File manager" })
--    bind("SUPER", "E", exec_cmd("emacsclient -c -a 'emacs'"), { description = "Launch Emacs" })
--
-- 4. REBINDING COMPOSITOR DISPATCHERS (e.g. workspace, fullscreen, floating):
--    unbind("SUPER", "Q")
--    bind("SUPER", "Q", dispatch("killactive"), { description = "Close active window" })
--    unbind("SUPER", "F") -- default fakefullscreen
--    bind("SUPER SHIFT", "F", dispatch("fullscreen", "0"), { description = "Toggle fullscreen" })
--    bind("SUPER ALT", "W", dispatch("workspace", "special:scratchpad"), { description = "Toggle scratchpad" })
--
-- 5. BIND OPTIONS (locked, repeating):
--    -- locked = true     -> runs even when lockscreen is active (e.g. media keys)
--    -- repeating = true  -> repeats when key is held down (e.g. volume / brightness)
--    bind("CTRL ALT", "bracketright", exec_cmd("$HOME/.config/hypr/scripts/Brightness.sh --inc"), { description = "Brightness up", repeating = true })
--    bind("", "XF86AudioMute", exec_cmd("$HOME/.config/hypr/scripts/Volume.sh --toggle"), { description = "Mute audio", locked = true })
--
-- =============================================================================
local user_keybinds_helper = nil
do
  local source = (debug.getinfo(1, "S") or {}).source or ""
  local source_path = source:match("^@(.+)$")
  local source_dir = source_path and source_path:match("^(.*)/[^/]+$") or nil
  local home = os.getenv("HOME") or ""
  local candidate_paths = {
    source_dir and (source_dir .. "/../lua/user_keybinds_helper.lua") or nil,
    home ~= "" and (home .. "/.config/hypr/lua/user_keybinds_helper.lua") or nil,
    home ~= "" and (home .. "/.config/hypr/user_keybinds_helper.lua") or nil,
  }

  local tried_paths = {}
  for _, helper_path in ipairs(candidate_paths) do
    if helper_path then
      table.insert(tried_paths, helper_path)
      local f = io.open(helper_path, "r")
      if f then
        f:close()
        local loaded_ok, loaded_helpers = pcall(dofile, helper_path)
        if loaded_ok and type(loaded_helpers) == "table" and loaded_helpers.bind then
          user_keybinds_helper = loaded_helpers
          break
        end
      end
    end
  end

  if not user_keybinds_helper then
    error("Failed to load user_keybinds_helper.lua from: " .. table.concat(tried_paths, ", "))
  end
end
local exec_cmd = user_keybinds_helper.exec_cmd
local dispatch = user_keybinds_helper.dispatch
local bind = user_keybinds_helper.bind
local unbind = user_keybinds_helper.unbind


-- BEGIN hypr-omarchy-tool resize
-- Managed resize aliases installed by hypr-omarchy-tool.
-- The block is self-contained so it also works on installations without the
-- KoolDots keybind helper.

local function resize_action(x, y)
  return function()
    if hl.dsp and hl.dsp.window and hl.dsp.window.resize then
      hl.dispatch(hl.dsp.window.resize({ x = x, y = y, relative = true }))
    else
      local command = "resizeactive " .. tostring(x) .. " " .. tostring(y)
      if hl.dsp and hl.dsp.exec_raw then
        hl.dispatch(hl.dsp.exec_raw(command))
      else
        hl.exec_cmd("hyprctl dispatch " .. command)
      end
    end
  end
end

local function bind_resize(mods, key, x, y, description)
  local chord = mods:gsub("%s+", " + ") .. " + " .. key
  if hl.unbind then
    pcall(hl.unbind, chord)
    pcall(hl.unbind, mods, key)
  end
  hl.bind(chord, resize_action(x, y), {
    description = description,
    repeating = true,
  })
end

-- Width: Super + plus / equal, Super + minus.
bind_resize("SUPER", "plus", 50, 0, "Expand window width")
bind_resize("SUPER", "equal", 50, 0, "Expand window width")
bind_resize("SUPER", "minus", -50, 0, "Shrink window width")

-- Height: add Shift.
bind_resize("SUPER SHIFT", "equal", 0, 50, "Expand window height")
bind_resize("SUPER SHIFT", "minus", 0, -50, "Shrink window height")

-- Fine and large steps.
bind_resize("SUPER ALT", "plus", 10, 0, "Expand window width slightly")
bind_resize("SUPER ALT", "minus", -10, 0, "Shrink window width slightly")
bind_resize("SUPER ALT SHIFT", "equal", 0, 10, "Expand window height slightly")
bind_resize("SUPER ALT SHIFT", "minus", 0, -10, "Shrink window height slightly")
bind_resize("SUPER CTRL", "plus", 100, 0, "Expand window width a lot")
bind_resize("SUPER CTRL", "minus", -100, 0, "Shrink window width a lot")
bind_resize("SUPER CTRL SHIFT", "equal", 0, 100, "Expand window height a lot")
bind_resize("SUPER CTRL SHIFT", "minus", 0, -100, "Shrink window height a lot")

-- Numpad aliases.
bind_resize("SUPER", "KP_Add", 50, 0, "Expand window width")
bind_resize("SUPER", "KP_Subtract", -50, 0, "Shrink window width")
bind_resize("SUPER SHIFT", "KP_Add", 0, 50, "Expand window height")
bind_resize("SUPER SHIFT", "KP_Subtract", 0, -50, "Shrink window height")
-- END hypr-omarchy-tool resize
