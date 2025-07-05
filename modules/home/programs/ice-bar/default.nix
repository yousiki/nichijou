{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.ice-bar = {
    enable = lib.mkEnableOption "Ice";
  };

  config =
    let
      cfg = config.${namespace}.programs.ice-bar;
    in
    lib.mkIf cfg.enable {
      home.packages = with pkgs; [ ice-bar ];
    };
}
