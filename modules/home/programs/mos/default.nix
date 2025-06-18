{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.mos = {
    enable = lib.mkEnableOption "Mos";
  };

  config =
    let
      cfg = config.${namespace}.programs.mos;
    in
    lib.mkIf cfg.enable {
      home.packages = with pkgs; [
        mos
      ];
    };
}
