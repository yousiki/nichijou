{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.raycast = {
    enable = lib.mkEnableOption "Raycast";
  };

  config = lib.mkIf config.${namespace}.programs.raycast.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isDarwin;
        message = "Raycast is only supported on macOS.";
      }
    ];

    home.packages = [ pkgs.brewCasks.raycast ];
  };
}
