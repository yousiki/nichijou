# Necessary packages for both NixOS and darwin.
{ pkgs, ... }:
{
  programs = {
    bash.enable = true;
    direnv.enable = true;
    fish.enable = true;
    man.enable = true;
    nix-index.enable = true;
    tmux.enable = true;
    vim.enable = true;
    zsh.enable = true;
  };

  environment.systemPackages = with pkgs; [
    bat
    btop
    coreutils-full
    curl
    dig
    dnslookup
    duf
    eza
    fd
    fzf
    gdu
    git
    gnumake
    helix
    home-manager
    htop
    jq
    neovim
    rclone
    ripgrep
    rsync
    unzip
    wget
    zellij
    zoxide
    zstd
  ];
}
