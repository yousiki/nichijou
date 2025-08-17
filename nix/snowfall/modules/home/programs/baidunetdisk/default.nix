{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.baidunetdisk = {
    enable = lib.mkEnableOption "Baidu Netdisk";
  };

  config = lib.mkIf config.${namespace}.programs.baidunetdisk.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isDarwin;
        message = "Baidu Netdisk is only supported on macOS.";
      }
    ];

    home.packages = [ pkgs.brewCasks.baidunetdisk ];
  };
}
