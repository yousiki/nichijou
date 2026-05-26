{ pkgs, ... }:

{
  environment.systemPackages = [
    pkgs.vim
  ];

  programs.zsh.enable = true;
}
