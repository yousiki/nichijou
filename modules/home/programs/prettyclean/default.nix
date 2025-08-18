{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.prettyclean = {
    enable = lib.mkEnableOption "PrettyClean";
  };

  config = lib.mkIf config.${namespace}.programs.prettyclean.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isDarwin;
        message = "PrettyClean is only supported on macOS.";
      }
    ];

    home.packages = [ pkgs.brewCasks.prettyclean ];
  };
}
