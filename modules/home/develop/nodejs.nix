{ pkgs, ... }:
{
  home.packages = with pkgs; [
    corepack
    nodejs
  ];
}
