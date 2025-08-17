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

  config = lib.mkIf config.${namespace}.programs.monitorcontrol.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isDarwin;
        message = "MonitorControl is only supported on macOS.";
      }
    ];

    home.packages = [ pkgs.monitorcontrol ];
  };
}
