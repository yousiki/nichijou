{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.qq = {
    enable = lib.mkEnableOption "QQ";
  };

  config = lib.mkIf config.${namespace}.programs.qq.enable {
    home.packages =
      let
        qq = with pkgs; if stdenv.hostPlatform.isDarwin then brewCasks.qq else qq;
      in
      [ qq ];
  };
}
