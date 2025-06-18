{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.alt-tab = {
    enable = lib.mkEnableOption "Alt-Tab";
  };

  config =
    let
      cfg = config.${namespace}.programs.alt-tab;
    in
    lib.mkIf cfg.enable {
      home.packages = [
        pkgs.${namespace}.alt-tab
      ];
    };
}
