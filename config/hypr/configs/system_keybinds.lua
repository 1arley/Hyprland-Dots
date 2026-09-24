-- ==================================================
--  Omarchy-compatible keybindings for this Hyprland setup
-- ==================================================
--
-- The key layout follows the stable Omarchy defaults (quattro), but the
-- commands use local fallbacks because this machine does not have Omarchy's
-- walker/omarchy-* commands installed.  This changes keyboard behavior only;
-- themes, bars, wallpaper, monitors, and window rules remain untouched.
--
-- Omarchy shortcuts are registered after the other KoolDots modules.  Existing
-- bindings are removed first so an old custom bind cannot run alongside a new
-- Omarchy bind.

local config_home = os.getenv("XDG_CONFIG_HOME") or ((os.getenv("HOME") or "") .. "/.config")
local hypr_dir = config_home .. "/hypr"
local helper_path = hypr_dir .. "/lua/keybind_helpers.lua"

local helper_ok, helpers = pcall(dofile, helper_path)
if not helper_ok or type(helpers) ~= "table" then
  error("Unable to load Hyprland keybind helper: " .. helper_path)
end

local bind = helpers.bind
local bindm = helpers.bindm
local dispatch = helpers.dispatch
local exec_cmd = helpers.exec_cmd
local raw_dispatch_cmd = helpers.raw_dispatch_cmd

local defaults = rawget(_G, "KOOLDOTS_DEFAULTS") or {}
local terminal = defaults.term or os.getenv("TERMINAL")
if terminal == nil or terminal == "" then
  terminal = "kitty"
end
local browser = os.getenv("BROWSER")
if browser == nil or browser == "" then
  browser = "firefox"
end
local file_manager = defaults.files or "thunar"
local editor = defaults.edit or os.getenv("EDITOR")
if editor == nil or editor == "" then
  editor = "micro"
end

local scripts = "$HOME/.config/hypr/scripts"
local rofi_config = "$HOME/.config/hypr/rofi/config.rasi"

local function bind_exec(mods, key, command, description, options)
  local opts = {}
  for option, value in pairs(options or {}) do
    opts[option] = value
  end
  opts.description = description
  bind(mods, key, exec_cmd(command), opts)
end

local function bind_dispatch(mods, key, name, args, description, options)
  local opts = {}
  for option, value in pairs(options or {}) do
    opts[option] = value
  end
  opts.description = description
  bind(mods, key, dispatch(name, args), opts)
end

-- Omarchy's universal clipboard shortcuts.  The small timer releases the
-- synthetic key state after the target application has consumed it.
local function send_shortcut_once(mods, key)
  return function()
    if not (hl and hl.dsp and hl.dsp.send_key_state) then
      return
    end
    hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))
    if hl.timer then
      hl.timer(function()
        hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
      end, { timeout = 50, type = "oneshot" })
    end
  end
end

-- Remove the currently registered binds before installing the new map.  This
-- is intentionally done through the Lua API so it also works during reloads.
local function modifier_string(mask)
  local mods = {}
  local function has(bit)
    return math.floor(mask / bit) % 2 == 1
  end
  if has(1) then table.insert(mods, "SHIFT") end
  if has(4) then table.insert(mods, "CTRL") end
  if has(8) then table.insert(mods, "ALT") end
  if has(16) then table.insert(mods, "MOD2") end
  if has(32) then table.insert(mods, "MOD3") end
  if has(64) then table.insert(mods, "SUPER") end
  if has(128) then table.insert(mods, "MOD5") end
  return table.concat(mods, " ")
end

local function unbind_chord(mods, key)
  if not (hl and hl.unbind) then
    return
  end
  local mods = modifier_string(mods)
  local chord = mods == "" and key or (mods .. " + " .. key)
  pcall(hl.unbind, chord)
  if mods ~= "" then
    pcall(hl.unbind, mods, key)
  end
end

local function clear_existing_binds()
  -- hyprctl is available in the compositor session.  If it is not available,
  -- the explicit fallback below still removes the usual default combinations.
  -- Do not call hyprctl from inside the Lua config loader: the compositor is
  -- already processing the reload and an IPC call would deadlock.  Reloads
  -- rebuild the keybind manager, so the explicit fallback below is enough.
  local fallback = {
    { 64, "Q" }, { 64, "W" }, { 64, "F" }, { 64, "P" }, { 64, "T" },
    { 64, "SPACE" }, { 64, "Return" }, { 64, "S" }, { 64, "L" },
    { 64, "left" }, { 64, "right" }, { 64, "up" }, { 64, "down" },
    { 64, "Tab" }, { 1, "Tab" }, { 65, "Tab" }, { 68, "Tab" },
    { 12, "Delete" }, { 64, "K" }, { 64, "E" }, { 64, "C" },
  }
  for _, item in ipairs(fallback) do
    unbind_chord(item[1], item[2])
  end
end

clear_existing_binds()

-- ============================================================
-- Applications
-- ============================================================
bind_exec("SUPER", "Return", terminal, "Terminal")
bind_exec("SUPER SHIFT", "Return", browser, "Browser")
bind_exec("SUPER SHIFT", "F", file_manager, "File manager")
bind_exec("SUPER ALT SHIFT", "F", 'thunar "$(pwd)"', "File manager (cwd)")
bind_exec("SUPER SHIFT", "B", browser, "Browser")
bind_exec("SUPER SHIFT ALT", "B", browser .. " --private", "Browser (private)")
bind_exec("SUPER SHIFT", "N", editor, "Editor")

-- Universal clipboard shortcuts from Omarchy.
bind("SUPER", "A", send_shortcut_once("CTRL", "A"), { description = "Select all" })
bind("SUPER", "C", send_shortcut_once("CTRL", "C"), { description = "Universal copy" })
bind("SUPER", "V", send_shortcut_once("CTRL", "V"), { description = "Universal paste" })
bind("SUPER", "X", send_shortcut_once("CTRL", "X"), { description = "Universal cut" })
bind_exec("SUPER CTRL", "V", scripts .. "/ClipManager.sh", "Clipboard manager")

-- ============================================================
-- Window and layout controls
-- ============================================================
bind_dispatch("SUPER", "W", "killactive", "", "Close window")
bind_dispatch("SUPER", "Q", "killactive", "", "Close window")
bind_exec("CTRL ALT", "Delete", scripts .. "/Logout.sh", "Exit Hyprland")

bind_dispatch("SUPER", "J", "togglesplit", "", "Toggle window split")
bind_dispatch("SUPER", "P", "pseudo", "", "Pseudo window")
bind_dispatch("SUPER", "T", "togglefloating", "", "Toggle window floating/tiling")
bind_dispatch("SUPER", "F", "fullscreen", "", "Full screen")
bind_dispatch("SUPER CTRL", "F", "fullscreen", "1", "Tiled full screen")
bind_dispatch("SUPER ALT", "F", "fullscreen", "1", "Full width")
bind_dispatch("SUPER", "O", "togglefloating", "", "Pop window out")
bind_exec("SUPER", "L", scripts .. "/ChangeLayout.sh toggle", "Toggle workspace layout")

bind_dispatch("SUPER", "left", "movefocus", "l", "Focus on left window")
bind_dispatch("SUPER", "right", "movefocus", "r", "Focus on right window")
bind_dispatch("SUPER", "up", "movefocus", "u", "Focus on above window")
bind_dispatch("SUPER", "down", "movefocus", "d", "Focus on below window")

-- Workspaces 1–10. Keycodes keep the mapping independent of keyboard layout.
for workspace = 1, 10 do
  local key = "code:" .. tostring(workspace + 9)
  bind_dispatch("SUPER", key, "workspace", tostring(workspace), "Switch to workspace " .. tostring(workspace))
  bind_dispatch("SUPER SHIFT", key, "movetoworkspace", tostring(workspace), "Move window to workspace " .. tostring(workspace))
  bind_dispatch(
    "SUPER SHIFT ALT",
    key,
    "movetoworkspacesilent",
    tostring(workspace),
    "Move window silently to workspace " .. tostring(workspace)
  )
end

bind_dispatch("SUPER", "S", "togglespecialworkspace", "scratchpad", "Toggle scratchpad")
bind_dispatch("SUPER ALT", "S", "movetoworkspace", "special:scratchpad", "Move window to scratchpad")
bind_dispatch("SUPER", "grave", "togglespecialworkspace", "scratchpad", "Toggle scratchpad")
bind_dispatch("SUPER SHIFT", "grave", "movetoworkspace", "special:scratchpad", "Move window to scratchpad")

bind_dispatch("SUPER", "Tab", "workspace", "e+1", "Next workspace")
bind_dispatch("SUPER SHIFT", "Tab", "workspace", "e-1", "Previous workspace")
bind_dispatch("SUPER CTRL", "Tab", "workspace", "previous", "Former workspace")

bind_dispatch("SUPER SHIFT ALT", "left", "movecurrentworkspacetomonitor", "l", "Move workspace to left monitor")
bind_dispatch("SUPER SHIFT ALT", "right", "movecurrentworkspacetomonitor", "r", "Move workspace to right monitor")
bind_dispatch("SUPER SHIFT ALT", "up", "movecurrentworkspacetomonitor", "u", "Move workspace to up monitor")
bind_dispatch("SUPER SHIFT ALT", "down", "movecurrentworkspacetomonitor", "d", "Move workspace to down monitor")

bind_dispatch("SUPER SHIFT", "left", "swapwindow", "l", "Swap window to the left")
bind_dispatch("SUPER SHIFT", "right", "swapwindow", "r", "Swap window to the right")
bind_dispatch("SUPER SHIFT", "up", "swapwindow", "u", "Swap window up")
bind_dispatch("SUPER SHIFT", "down", "swapwindow", "d", "Swap window down")

bind_dispatch("ALT", "Tab", "cyclenext", "", "Focus on next window")
bind_dispatch("ALT SHIFT", "Tab", "cyclenext", "prev", "Focus on previous window")
bind_dispatch("ALT", "Tab", "bringactivetotop", "", "Reveal active window on top")
bind_dispatch("ALT SHIFT", "Tab", "bringactivetotop", "", "Reveal active window on top")
bind("CTRL ALT", "Tab", raw_dispatch_cmd("focusmonitor +1"), { description = "Focus on next monitor" })
bind("CTRL ALT SHIFT", "Tab", raw_dispatch_cmd("focusmonitor -1"), { description = "Focus on previous monitor" })

-- Resize shortcuts use the same physical bracket keys as Omarchy.
bind_dispatch("SUPER", "bracketleft", "resizeactive", "-100 0", "Expand window left", { repeating = true })
bind_dispatch("SUPER", "bracketright", "resizeactive", "100 0", "Shrink window left", { repeating = true })
bind_dispatch("SUPER SHIFT", "bracketleft", "resizeactive", "0 -100", "Shrink window up", { repeating = true })
bind_dispatch("SUPER SHIFT", "bracketright", "resizeactive", "0 100", "Expand window down", { repeating = true })
bind_dispatch("SUPER ALT", "bracketleft", "resizeactive", "-25 0", "Expand window left a little", { repeating = true })
bind_dispatch("SUPER ALT", "bracketright", "resizeactive", "25 0", "Shrink window left a little", { repeating = true })
bind_dispatch("SUPER SHIFT ALT", "bracketleft", "resizeactive", "0 -25", "Shrink window up a little", { repeating = true })
bind_dispatch("SUPER SHIFT ALT", "bracketright", "resizeactive", "0 25", "Expand window down a little", { repeating = true })
bind_dispatch("SUPER CTRL", "bracketleft", "resizeactive", "-300 0", "Expand window left a lot", { repeating = true })
bind_dispatch("SUPER CTRL", "bracketright", "resizeactive", "300 0", "Shrink window left a lot", { repeating = true })
bind_dispatch("SUPER CTRL SHIFT", "bracketleft", "resizeactive", "0 -300", "Shrink window up a lot", { repeating = true })
bind_dispatch("SUPER CTRL SHIFT", "bracketright", "resizeactive", "0 300", "Expand window down a lot", { repeating = true })

bind_dispatch("SUPER", "mouse_down", "workspace", "e+1", "Scroll active workspace forward")
bind_dispatch("SUPER", "mouse_up", "workspace", "e-1", "Scroll active workspace backward")
bindm("SUPER", "mouse:272", "movewindow", "Move window")
bindm("SUPER", "mouse:273", "resizewindow", "Resize window")

-- Group controls
bind_dispatch("SUPER", "G", "togglegroup", "", "Toggle window grouping")
bind_dispatch("SUPER ALT", "G", "moveoutofgroup", "", "Move active window out of group")
bind_dispatch("SUPER ALT", "left", "moveintogroup", "l", "Move window to group on left")
bind_dispatch("SUPER ALT", "right", "moveintogroup", "r", "Move window to group on right")
bind_dispatch("SUPER ALT", "up", "moveintogroup", "u", "Move window to group on top")
bind_dispatch("SUPER ALT", "down", "moveintogroup", "d", "Move window to group on bottom")
bind_dispatch("SUPER ALT", "Tab", "changegroupactive", "f", "Next window in group")
bind_dispatch("SUPER ALT SHIFT", "Tab", "changegroupactive", "b", "Previous window in group")
bind_dispatch("SUPER CTRL", "left", "changegroupactive", "b", "Move grouped window focus left")
bind_dispatch("SUPER CTRL", "right", "changegroupactive", "f", "Move grouped window focus right")

-- ============================================================
-- Menus and utilities
-- ============================================================
local launcher = "pkill rofi || true; rofi -show drun -modi drun,filebrowser,run,window -config " .. rofi_config
local menu = "pkill rofi || true; rofi -show drun -modi drun,run,window -config " .. rofi_config

bind_exec("SUPER", "SPACE", launcher, "Launch apps")
bind_exec("SUPER ALT", "SPACE", menu, "Omarchy menu")
bind_exec("SUPER CTRL", "E", scripts .. "/RofiEmoji.sh", "Emoji picker")
bind_exec("SUPER CTRL", "C", scripts .. "/ScreenShot.sh --now", "Capture menu")
bind_exec("SUPER CTRL", "O", scripts .. "/OverviewToggle.sh", "Toggle menu")
bind_exec("SUPER CTRL", "H", "pavucontrol", "Hardware menu")
bind_exec("SUPER SHIFT", "code:201", "wlogout", "Omarchy menu")
bind_exec("SUPER", "Escape", "wlogout", "System menu")
bind_exec("", "XF86PowerOff", "wlogout", "Power menu", { locked = true })
bind_exec("SUPER", "K", scripts .. "/KeyBinds.sh", "Keybindings")
bind_exec("SUPER ALT", "K", scripts .. "/KeyBinds.sh", "Tmux keybindings")
bind_exec("SUPER CTRL", "Q", "kcalc", "Calculator")
bind_exec("", "XF86Calculator", "kcalc", "Calculator")

bind_exec("SUPER SHIFT", "SPACE", "pkill -SIGUSR1 waybar || true", "Toggle top bar")
bind_exec("SUPER CTRL", "SPACE", scripts .. "/WallpaperSelect.sh", "Background switcher")
bind_exec("SUPER SHIFT CTRL", "SPACE", scripts .. "/ThemeChanger.sh", "Theme menu")
bind_exec("SUPER", "BackSpace", scripts .. "/ToggleOpacity.sh", "Toggle window transparency")
bind_exec("SUPER SHIFT", "BackSpace", scripts .. "/ChangeBlur.sh", "Toggle window gaps")
bind_exec("SUPER CTRL", "BackSpace", scripts .. "/ToggleOpacity.sh", "Toggle single-window aspect")

bind_exec("SUPER", "comma", "swaync-client --close-latest", "Dismiss last notification")
bind_exec("SUPER SHIFT", "comma", "swaync-client --close-all", "Dismiss all notifications")
bind_exec("SUPER CTRL", "comma", "swaync-client --toggle-dnd", "Toggle silencing notifications")
bind_exec("SUPER ALT", "comma", "swaync-client --action", "Invoke last notification")
bind_exec("SUPER SHIFT ALT", "comma", "swaync-client --toggle-panel", "Open notification history")

bind_exec("SUPER CTRL", "N", scripts .. "/Hyprsunset.sh toggle", "Toggle nightlight")
bind_exec("SUPER CTRL", "L", scripts .. "/LockScreen.sh", "Lock system")
bind_exec("SUPER CTRL", "A", "pavucontrol", "Audio controls")
bind_exec("SUPER CTRL", "B", "pavucontrol", "Bluetooth controls")
bind_exec("SUPER CTRL", "W", "nm-connection-editor", "Wifi controls")
bind_exec("SUPER CTRL", "T", "btop", "Activity")
bind_exec("SUPER CTRL", "Z", scripts .. "/Zoom.sh in", "Zoom in")
bind_exec("SUPER CTRL ALT", "Z", scripts .. "/Zoom.sh out", "Reset zoom")

-- Screenshots and capture.  The local setup does not include Omarchy's
-- screen-recording/OCR helpers, so those shortcuts use the closest local tool.
bind_exec("", "Print", scripts .. "/ScreenShot.sh --now", "Screenshot")
bind_exec("ALT", "Print", scripts .. "/ScreenShot.sh --in5", "Screen capture (5s)")
bind_exec("SUPER", "Print", "hyprpicker -a", "Color picker")
bind_exec("SUPER CTRL", "Print", scripts .. "/ScreenShot.sh --now", "Extract text from screenshot")
bind_exec("SUPER CTRL", "S", scripts .. "/ScreenShot.sh --swappy", "Share")

-- ============================================================
-- Audio, media, brightness, and hardware keys
-- ============================================================
local locked_repeat = { locked = true, repeating = true }
bind_exec("", "XF86AudioRaiseVolume", scripts .. "/Volume.sh --inc", "Volume up", locked_repeat)
bind_exec("", "XF86AudioLowerVolume", scripts .. "/Volume.sh --dec", "Volume down", locked_repeat)
bind_exec("ALT", "XF86AudioRaiseVolume", scripts .. "/Volume.sh --inc-precise", "Volume up precise", locked_repeat)
bind_exec("ALT", "XF86AudioLowerVolume", scripts .. "/Volume.sh --dec-precise", "Volume down precise", locked_repeat)
bind_exec("", "XF86AudioMute", scripts .. "/Volume.sh --toggle", "Mute", locked_repeat)
bind_exec("", "XF86AudioMicMute", scripts .. "/Volume.sh --toggle-mic", "Mute microphone", locked_repeat)

bind_exec("", "XF86MonBrightnessUp", scripts .. "/Brightness.sh --inc", "Brightness up", locked_repeat)
bind_exec("", "XF86MonBrightnessDown", scripts .. "/Brightness.sh --dec", "Brightness down", locked_repeat)
bind_exec("SHIFT", "XF86MonBrightnessUp", scripts .. "/Brightness.sh --inc", "Brightness maximum", locked_repeat)
bind_exec("SHIFT", "XF86MonBrightnessDown", scripts .. "/Brightness.sh --dec", "Brightness minimum", locked_repeat)
bind_exec("", "XF86KbdBrightnessUp", scripts .. "/BrightnessKbd.sh --inc", "Keyboard brightness up", locked_repeat)
bind_exec("", "XF86KbdBrightnessDown", scripts .. "/BrightnessKbd.sh --dec", "Keyboard brightness down", locked_repeat)
bind_exec("", "XF86KbdLightOnOff", scripts .. "/BrightnessKbd.sh --cycle", "Keyboard backlight cycle", { locked = true })
bind_exec("", "XF86TouchpadToggle", scripts .. "/TouchPad.sh", "Toggle touchpad", { locked = true })

bind_exec("", "XF86AudioNext", scripts .. "/MediaCtrl.sh --nxt", "Next track", { locked = true })
bind_exec("", "XF86AudioPause", scripts .. "/MediaCtrl.sh --pause", "Pause", { locked = true })
bind_exec("", "XF86AudioPlay", scripts .. "/MediaCtrl.sh --pause", "Play", { locked = true })
bind_exec("", "XF86AudioPrev", scripts .. "/MediaCtrl.sh --prv", "Previous track", { locked = true })
bind_exec("", "XF86AudioStop", scripts .. "/MediaCtrl.sh --stop", "Stop", { locked = true })
