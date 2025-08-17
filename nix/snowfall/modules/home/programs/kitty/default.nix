{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.kitty = {
    enable = lib.mkEnableOption "kitty";
  };

  config = lib.mkIf config.${namespace}.programs.kitty.enable {
    programs.kitty = {
      enable = true;
      package = pkgs.kitty;
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
  };
}
