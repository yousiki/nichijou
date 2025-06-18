local config = {}
if wezterm.config_builder then
  config = wezterm.config_builder()
end
if catppuccin_plugin then
  dofile(catppuccin_plugin).apply_to_config(config)
end
config.font = wezterm.font("CaskaydiaCove Nerd Font Mono")
config.font_size = 12.0
return config
