{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.raycast = {
    enable = lib.mkEnableOption "Raycast";
  };

  config =
    let
      cfg = config.${namespace}.programs.raycast;
    in
    lib.mkIf cfg.enable {
      home.packages = with pkgs; [
        raycast
      ];
    };
}
