{ pkgs, ... }:
{
  home.packages = with pkgs; [
    deadnix
    nil
    nixd
    nixfmt-rfc-style
    statix
  ];

  programs.nh.enable = true;
}
