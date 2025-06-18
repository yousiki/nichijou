{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:

{
  options.${namespace}.programs.duf = {
    enable = lib.mkEnableOption "duf";
  };

  config =
    let
      cfg = config.${namespace}.programs.duf;
    in
    lib.mkIf cfg.enable { home.packages = with pkgs; [ duf ]; };
}
