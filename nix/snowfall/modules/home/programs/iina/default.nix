{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.iina = {
    enable = lib.mkEnableOption "IINA";
  };

  config = lib.mkIf config.${namespace}.programs.iina.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isDarwin;
        message = "IINA is only supported on macOS.";
      }
    ];

    home.packages = [ pkgs.brewCasks.iina ];
  };
}
