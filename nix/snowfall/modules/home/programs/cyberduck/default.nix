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

  config = lib.mkIf config.${namespace}.programs.cyberduck.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isDarwin;
        message = "Cyberduck is only supported on macOS.";
      }
    ];

    home.packages = [ pkgs.brewCasks.cyberduck ];
  };
}
