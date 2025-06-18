{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.bat = {
    enable = lib.mkEnableOption "bat";
  };

  config =
    let
      cfg = config.${namespace}.programs.bat;
    in
    lib.mkIf cfg.enable {
      programs.bat = {
        enable = true;
        extraPackages = with pkgs.bat-extras; [
          batdiff
          batgrep
          batman
          batpipe
          batwatch
          prettybat
        ];
      };
    };
}
