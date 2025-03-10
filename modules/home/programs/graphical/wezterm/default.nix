{
  lib,
  pkgs,
  namespace,
  config,
  ...
}: let
  cfg = config.${namespace}.programs.graphical.wezterm;
in {
  options.${namespace}.programs.graphical.wezterm = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable wezterm.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.wezterm = {
      enable = true;
      package = pkgs.wezterm;
      enableBashIntegration = true;
      enableZshIntegration = true;
      extraConfig = builtins.readFile ./wezterm.lua;
    };
  };
}
