-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- Theme & colors
config.color_scheme = 'rose-pine'
config.default_cursor_style = 'BlinkingBar'

-- Font and related settings
config.font = wezterm.font_with_fallback {
    {
        family = "M PLUS Code Latin",
        weight = "Regular",
        stretch = "Normal",
        style = "Normal"
    },
    "IosevkaTerm Nerd Font Propo"
}
config.font_size = 14
config.line_height = 1.2
-- Window & tabs style
config.window_decorations = "RESIZE"
config.window_background_opacity = 0.96
config.macos_window_background_blur = 16
config.hide_tab_bar_if_only_one_tab = true
config.window_padding = {
    left = 16,
    right = 16,
    top = 8,
    bottom = 8,
}
config.inactive_pane_hsb = {
    saturation = 0.8,
    brightness = 0.7
}

--- Custom tab bar
local bar = wezterm.plugin.require("https://github.com/adriankarlen/bar.wezterm")
bar.apply_to_config(config, {
    position = "bottom",
    max_width = 32,
    separator_space = 0.5,
    left_separator = "",
    right_separator = "",
    field_separator = "",
    leader_icon = "",
    workspace_icon = "",
    pane_icon = nil,
    user_icon = "",
    hostname_icon = "",
    clock_icon = "",
    cwd_icon = "",
    enabled_modules = {
        workspace = true,
        pane = false,
        username = false,
        hostname = false,
        clock = true,
        cwd = false,
    }
})
config.colors.tab_bar = {
    background = "#393552",
    active_tab = {
        bg_color = "#393552",
        fg_color = "#f6c177",
    },
    inactive_tab = {
        bg_color = "#393552",
        fg_color = "#6e6a86",
    },
}

-- No annoyances
config.audible_bell = "Disabled"

-- Keyboard mapping
config.disable_default_key_bindings = false

-- Set custom startup position
-- wezterm.on('gui-startup', function(cmd)
--     local screens = wezterm.gui.screens()
--     local active = screens.active
--     local width = active.width * 0.5
--     local x = ((active.width - width) / 2) + math.abs(screens.origin_x)
--     local tab, pane, window = wezterm.mux.spawn_window(cmd or {
--         position = { x = x, y = 0 },
--     })
--     window:gui_window():set_inner_size(width, active.height)
-- end)

-- Done!
return config
