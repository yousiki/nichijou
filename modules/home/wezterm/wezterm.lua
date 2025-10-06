local wezterm = require "wezterm"

local function scheme_for_appearance(appearance)
    if appearance:find "Dark" then
        return "Catppuccin Mocha"
    else
        return "Catppuccin Frappe"
    end
end

return {
    -- Font configuration
    font = wezterm.font_with_fallback {
        "Maple Mono NF CN",
        "JetBrains Mono",
        "monospace"
    },
    font_size = 13.0,
    line_height = 1.0,

    -- Color scheme (based on system appearance)
    color_scheme = scheme_for_appearance(wezterm.gui.get_appearance()),

    -- Window appearance
    window_padding = {
        left = 5,
        right = 5,
        top = 5,
        bottom = 5,
    },
    window_background_opacity = 0.95,
    window_decorations = "RESIZE",

    -- Tab bar
    enable_tab_bar = true,
    tab_bar_at_bottom = false,
    use_fancy_tab_bar = true,
    hide_tab_bar_if_only_one_tab = true,

    colors = {
        tab_bar = {
            -- The color of the active tab
            active_tab = {
                bg_color = '#1e1e2e',
                fg_color = '#cdd6f4',
                intensity = 'Bold',
                underline = 'None',
                italic = false,
                strikethrough = false,
            },
            -- The color of the inactive tabs
            inactive_tab = {
                bg_color = '#11111b',
                fg_color = '#a6adc8',
                intensity = 'Normal',
                underline = 'None',
                italic = false,
                strikethrough = false,
            },
            -- The color of the inactive tab when hovered
            inactive_tab_hover = {
                bg_color = '#313244',
                fg_color = '#cdd6f4',
                intensity = 'Normal',
                underline = 'None',
                italic = false,
                strikethrough = false,
            },
            -- The new tab button
            new_tab = {
                bg_color = '#11111b',
                fg_color = '#a6adc8',
                intensity = 'Normal',
                underline = 'None',
                italic = false,
                strikethrough = false,
            },
            -- The new tab button when hovered
            new_tab_hover = {
                bg_color = '#313244',
                fg_color = '#cdd6f4',
                intensity = 'Normal',
                underline = 'None',
                italic = false,
                strikethrough = false,
            },
            -- The background of the tab bar
            background = '#11111b',
        },
    },

    -- Cursor
    default_cursor_style = "SteadyBlock",
    cursor_blink_rate = 500,

    -- Window options
    adjust_window_size_when_changing_font_size = false,
    enable_scroll_bar = false,
}
