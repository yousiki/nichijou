{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.keka = {
    enable = lib.mkEnableOption "Keka";
  };

  config = lib.mkIf config.${namespace}.programs.keka.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isDarwin;
        message = "Keka is only supported on macOS.";
      }
    ];

    home.packages = [ pkgs.keka ];
  };
}
