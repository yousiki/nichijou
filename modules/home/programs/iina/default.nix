{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.iina = {
    enable = lib.mkEnableOption "IINA";
  };

  config =
    let
      cfg = config.${namespace}.programs.iina;
    in
    lib.mkIf cfg.enable {
      home.packages = with pkgs; [
        iina
      ];
    };
}
