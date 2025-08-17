{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.maccy = {
    enable = lib.mkEnableOption "Maccy";
  };

  config = lib.mkIf config.${namespace}.programs.maccy.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isDarwin;
        message = "Maccy is only supported on macOS.";
      }
    ];

    home.packages = [ pkgs.maccy ];
  };
}
