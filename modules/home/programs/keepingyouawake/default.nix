{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.keepingyouawake = {
    enable = lib.mkEnableOption "KeepingYouAwake";
  };

  config =
    let
      cfg = config.${namespace}.programs.keepingyouawake;
    in
    lib.mkIf cfg.enable {
      home.packages = [
        pkgs.${namespace}.keepingyouawake
      ];
    };
}
