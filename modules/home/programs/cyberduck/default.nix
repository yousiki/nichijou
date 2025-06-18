{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.cyberduck = {
    enable = lib.mkEnableOption "Cyberduck";
  };

  config =
    let
      cfg = config.${namespace}.programs.cyberduck;
    in
    lib.mkIf cfg.enable {
      home.packages = with pkgs; [
        cyberduck
      ];
    };
}
