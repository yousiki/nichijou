{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.nil = {
    enable = lib.mkEnableOption "nil";
  };

  config =
    let
      cfg = config.${namespace}.programs.nil;
    in
    lib.mkIf cfg.enable {
      home.packages = with pkgs; [
        nil
      ];
    };
}
