{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.kitty = {
    enable = lib.mkEnableOption "Kitty";
  };

  config =
    let
      cfg = config.${namespace}.programs.kitty;
    in
    lib.mkIf cfg.enable {
      # Enable and configure kitty.
      programs.kitty = {
        enable = true;
        font = {
          name = "CaskaydiaCove Nerd Font Mono";
          size = 13;
          package = pkgs.nerd-fonts.caskaydia-mono;
        };
        shellIntegration = {
          enableBashIntegration = true;
          enableFishIntegration = true;
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
