{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.rectangle = {
    enable = lib.mkEnableOption "Rectangle";
  };

  config = lib.mkIf config.${namespace}.programs.rectangle.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isDarwin;
        message = "Rectangle is only supported on macOS.";
      }
    ];

    home.packages = [ pkgs.rectangle ];
  };
}
