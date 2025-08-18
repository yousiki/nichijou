{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.fonts = {
    enable = lib.mkEnableOption "fonts";
  };

  config = lib.mkIf config.${namespace}.fonts.enable {
    fonts.packages = with pkgs; [
      nerd-fonts.caskaydia-cove
      nerd-fonts.caskaydia-mono
      nerd-fonts.zed-mono
    ];
  };
}
