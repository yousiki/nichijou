{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.keka = {
    enable = lib.mkEnableOption "Keka";
  };

  config =
    let
      cfg = config.${namespace}.programs.keka;
    in
    lib.mkIf cfg.enable {
      home.packages = with pkgs; [
        keka
      ];
    };
}
