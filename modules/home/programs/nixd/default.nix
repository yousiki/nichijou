{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.nixd = {
    enable = lib.mkEnableOption "nixd";
  };

  config =
    let
      cfg = config.${namespace}.programs.nixd;
    in
    lib.mkIf cfg.enable {
      home.packages = with pkgs; [
        nixd
      ];
    };
}
