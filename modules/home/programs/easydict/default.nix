{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.easydict = {
    enable = lib.mkEnableOption "EasyDict";
  };

  config = lib.mkIf config.${namespace}.programs.easydict.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isDarwin;
        message = "EasyDict is only supported on macOS.";
      }
    ];

    home.packages = [ pkgs.brewCasks.easydict ];
  };
}
