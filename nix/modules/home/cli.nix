{ pkgs, ... }:

{
  home.packages = [
    pkgs.claude-code
    pkgs.ripgrep
    pkgs.fd
    pkgs.jq
  ];

  programs.git = {
    enable = true;
  };
}
