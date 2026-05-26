{ pkgs, ... }:

{
  home.enableNixpkgsReleaseCheck = false;

  home.packages = [
    pkgs.git
  ];

  programs.home-manager.enable = true;
}
