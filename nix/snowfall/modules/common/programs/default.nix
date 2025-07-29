# Basic programs for all systems.
{ pkgs, ... }:
{
  programs = {
    tmux.enable = true;
    zsh.enable = true;
  };

  environment.systemPackages = with pkgs; [
    curl
    git
    neovim
    wget
  ];
}
