# Basic shell environment
{ pkgs, ... }:
{
  programs = {
    fish.enable = true;
    tmux.enable = true;
    zsh.enable = true;
  };
  environment.systemPackages = with pkgs; [
    coreutils
    curl
    dig
    duf
    eza
    git
    jq
    unzip
    wget
    zoxide
  ];
}
