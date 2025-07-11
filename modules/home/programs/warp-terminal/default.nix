{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.warp-terminal = {
    enable = lib.mkEnableOption "warp-terminal";
  };

  config =
    let
      cfg = config.${namespace}.programs.warp-terminal;
    in
    lib.mkIf cfg.enable {
      home.packages = with pkgs; [
        warp-terminal
      ];
    };
}
