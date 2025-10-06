_: {
  programs.wezterm = {
    enable = true;
    enableZshIntegration = true;
    extraConfig = builtins.readFile ./wezterm.lua;
  };

  catppuccin.wezterm.enable = false;
}
