{ pkgs, ... }:

{
  imports = [
    ./programs/claude-code.nix
    ./programs/codex.nix
    ./programs/opencode.nix
    ./programs/mole.nix
    ./programs/cliproxyapi.nix
    ./programs/git.nix
    ./programs/shell.nix
    ./programs/toolchains.nix
  ];

  home.packages = [
    pkgs.ripgrep
    pkgs.fd
    pkgs.jq
  ];
}
