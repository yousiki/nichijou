{
  config,
  lib,
  namespace,
  ...
}:
{
  options.${namespace}.programs.wezterm = {
    enable = lib.mkEnableOption "Wezterm";
  };

  config =
    let
      cfg = config.${namespace}.programs.wezterm;
    in
    lib.mkIf cfg.enable {
      programs.wezterm = {
        enable = true;
        enableBashIntegration = true;
        enableZshIntegration = true;
        extraConfig = lib.readFile ./wezterm.lua;
      };
    };
}
