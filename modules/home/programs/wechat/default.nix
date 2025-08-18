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
    home.packages =
      let
        wechat = with pkgs; if stdenv.hostPlatform.isDarwin then brewCasks.wechat else wechat;
      in
      [ wechat ];
  };
}
