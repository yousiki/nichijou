# Common configuration for fonts
{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.fonts = {
    enable = lib.mkEnableOption "Fonts support";
    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = with pkgs; [
        maple-mono.NF-CN
        nerd-fonts.caskaydia-cove
        nerd-fonts.caskaydia-mono
        nerd-fonts.fira-code
        nerd-fonts.fira-mono
        nerd-fonts.jetbrains-mono
        nerd-fonts.zed-mono
      ];
      description = "List of font packages to install.";
    };
  };

  config =
    let
      cfg = config.${namespace}.fonts;
    in
    lib.mkIf cfg.enable {
      fonts.packages = cfg.packages;
    };
}
