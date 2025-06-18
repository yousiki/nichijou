{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.maccy = {
    enable = lib.mkEnableOption "Maccy";
  };

  config =
    let
      cfg = config.${namespace}.programs.maccy;
    in
    lib.mkIf cfg.enable {
      home.packages = with pkgs; [
        maccy
      ];
    };
}
