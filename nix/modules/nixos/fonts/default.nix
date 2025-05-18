{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
let
  cfg = config.${namespace}.fonts;
in
{
  options.${namespace}.fonts = {
    enable = lib.mkEnableOption "Whether to enable fonts";
  };

  config = lib.mkIf cfg.enable {
    fonts = {
      enableDefaultPackages = true;
      fontDir = {
        enable = true;
        decompressFonts = true;
      };
      packages = with pkgs; [
        nerd-fonts.caskaydia-cove
        nerd-fonts.caskaydia-mono
      ];
    };
  };
}
