# Configure Kitty terminal for desktops.
{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
lib.mkIf (builtins.elem "desktop" config.${namespace}.tags) {
  programs.kitty = {
    enable = true;
    # Install Kitty via Homebrew cask on macOS.
    package = if pkgs.stdenv.hostPlatform.isDarwin then pkgs.emptyDirectory else pkgs.kitty;
    font = {
      name = "CaskaydiaCove Nerd Font Mono";
      package = pkgs.nerd-fonts.caskaydia-mono;
      size = 13;
    };
    shellIntegration = {
      enableZshIntegration = true;
    };
    extraConfig = ''
      tab_bar_min_tabs    1
      tab_bar_edge        bottom
      tab_bar_style       powerline
      tab_powerline_style slanted
      tab_title_template  {title}{" :{}:".format(num_windows) if num_windows > 1 else ""}
    '';
  };
  # Add shell aliases for kitty.
  home.shellAliases = {
    kssh = "kitty +kitten ssh";
  };
}
