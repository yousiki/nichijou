{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.feishu = {
    enable = lib.mkEnableOption "Feishu";
  };

  config =
    let
      feishu = with pkgs; if stdenv.hostPlatform.isDarwin then brewCasks.feishu else feishu;
    in
    lib.mkIf config.${namespace}.programs.feishu.enable {
      home.packages = [ feishu ];
    };
}
