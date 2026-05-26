{ pkgs, ... }:

{
  home.packages = [
    pkgs.ripgrep
    pkgs.fd
    pkgs.jq
  ];

  programs.git = {
    enable = true;
  };
}
