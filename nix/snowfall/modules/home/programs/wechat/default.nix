{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.wechat = {
    enable = lib.mkEnableOption "WeChat";
  };

  config = lib.mkIf config.${namespace}.programs.wechat.enable {
    home.packages = [ pkgs.wechat ];
  };
}
