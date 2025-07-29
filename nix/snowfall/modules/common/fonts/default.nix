# Install fonts to systems tagged with "desktop".
{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  config = lib.mkIf (builtins.elem "desktop" config.${namespace}.tags) {
    fonts.packages = with pkgs; [
      maple-mono.NF-CN
      nerd-fonts.caskaydia-cove
      nerd-fonts.caskaydia-mono
      nerd-fonts.fira-code
      nerd-fonts.fira-mono
      nerd-fonts.jetbrains-mono
      nerd-fonts.zed-mono
    ];
  };
}
