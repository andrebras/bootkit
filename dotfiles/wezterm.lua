-- WezTerm API & base config
local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Disable anoying audible bell
config.audible_bell = "Disabled"

-- Do not ask for confirmation when closing windows/tabs
config.window_close_confirmation = "NeverPrompt"

-- Font style
config.font = wezterm.font("JetBrainsMono Nerd Font Mono")
config.font_size = 14.5
config.bold_brightens_ansi_colors = false

-- Blinking block cursor
config.default_cursor_style = "BlinkingBlock"

-- Cursor blink: 600 ms period
config.cursor_blink_rate = 600

-- Do not fade the cursor in/out, just toggle
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"

-- Hide mouse cursor while typing
config.hide_mouse_cursor_when_typing = true

-- Minimal tab bar
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true

-- Slight transparency, aesthetic without harming readability
config.window_background_opacity = 1.0

-- macOS normal window decorations
config.window_decorations = "TITLE | RESIZE"

-- Colors: automatic switching between Tokyo Night / Day
if wezterm.gui then
  local appearance = wezterm.gui.get_appearance()

  config.color_scheme = appearance:find("Dark")
    and "Tokyo Night"
    or "Tokyo Night Day"

  wezterm.on("window-config-reloaded", function(window)
    local overrides = window:get_config_overrides() or {}
    local a = wezterm.gui.get_appearance()

    overrides.color_scheme = a:find("Dark")
      and "Tokyo Night"
      or "Tokyo Night Day"

    window:set_config_overrides(overrides)
  end)
end

-- Maximize the first window when the GUI starts
local mux = wezterm.mux

wezterm.on("gui-startup", function(cmd)
  local _, _, window = mux.spawn_window(cmd or {})
  window:gui_window():maximize()
end)

return config
