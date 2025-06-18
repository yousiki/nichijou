{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:

{
  options.${namespace}.programs.gdu = {
    enable = lib.mkEnableOption "gdu";
  };

  config =
    let
      cfg = config.${namespace}.programs.gdu;
    in
    lib.mkIf cfg.enable { home.packages = with pkgs; [ gdu ]; };
}
