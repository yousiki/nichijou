{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.mos = {
    enable = lib.mkEnableOption "Mos";
  };

  config = lib.mkIf config.${namespace}.programs.mos.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isDarwin;
        message = "Mos is only supported on macOS.";
      }
    ];

    home.packages = [ pkgs.brewCasks.mos ];
  };
}
