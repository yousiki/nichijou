{ pkgs, ... }:

{
  environment.systemPackages = [
    pkgs.vim
  ];

  fonts.packages = [
    pkgs.maple-mono.NF-CN-unhinted
  ];

  programs.zsh.enable = true;
}
