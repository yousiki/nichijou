{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.monitorcontrol = {
    enable = lib.mkEnableOption "MonitorControl";
  };

  config =
    let
      cfg = config.${namespace}.programs.monitorcontrol;
    in
    lib.mkIf cfg.enable {
      home.packages = with pkgs; [
        monitorcontrol
      ];
    };
}
