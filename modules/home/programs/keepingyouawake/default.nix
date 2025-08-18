{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.keepingyouawake = {
    enable = lib.mkEnableOption "KeepingYouAwake";
  };

  config = lib.mkIf config.${namespace}.programs.keepingyouawake.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isDarwin;
        message = "KeepingYouAwake is only supported on macOS.";
      }
    ];

    home.packages = [ pkgs.brewCasks.keepingyouawake ];
  };
}
