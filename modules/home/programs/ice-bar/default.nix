{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.ice-bar = {
    enable = lib.mkEnableOption "Ice Bar";
  };

  config = lib.mkIf config.${namespace}.programs.ice-bar.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isDarwin;
        message = "Ice Bar is only supported on macOS.";
      }
    ];

    home.packages = [ pkgs.brewCasks.jordanbaird-ice ];
  };
}
