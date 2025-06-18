{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.rectangle = {
    enable = lib.mkEnableOption "Rectangle";
  };

  config =
    let
      cfg = config.${namespace}.programs.rectangle;
    in
    lib.mkIf cfg.enable {
      home.packages = [
        pkgs.rectangle
      ];
    };
}
