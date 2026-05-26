{ pkgs, ... }:

{
  imports = [
    ./programs/claude-code.nix
    ./programs/codex.nix
    ./programs/git.nix
    ./programs/shell.nix
  ];

  home.packages = [
    pkgs.ripgrep
    pkgs.fd
    pkgs.jq
  ];
}
