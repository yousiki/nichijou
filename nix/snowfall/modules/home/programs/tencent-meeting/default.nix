{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.tencent-meeting = {
    enable = lib.mkEnableOption "Tencent Meeting";
  };

  config = lib.mkIf config.${namespace}.programs.tencent-meeting.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isDarwin;
        message = "Tencent Meeting is only supported on macOS.";
      }
    ];

    home.packages = [ pkgs.brewCasks.tencent-meeting ];
  };
}
