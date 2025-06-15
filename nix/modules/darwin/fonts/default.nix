{
  pkgs,
  ...
}:
{
  fonts.packages = with pkgs; [
    nerd-fonts.caskaydia-cove
    nerd-fonts.caskaydia-mono
  ];
}
