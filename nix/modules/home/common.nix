{ pkgs, ... }:

{
  home.packages = [
    pkgs.git
  ];

  programs.home-manager.enable = true;
}
