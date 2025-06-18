{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.ice = {
    enable = lib.mkEnableOption "Ice";
  };

  config =
    let
      cfg = config.${namespace}.programs.ice;
    in
    lib.mkIf cfg.enable {
      home.packages = [
        pkgs.${namespace}.ice
      ];
    };
}
