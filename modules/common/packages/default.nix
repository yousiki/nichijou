{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    coreutils-full
    curl
    eza
    fd
    fzf
    git
    gnumake
    helix
    home-manager
    htop
    jq
    man
    neovim
    rclone
    ripgrep
    rsync
    tmux
    unzip
    vim
    wget
    zellij
    zoxide
    zstd
  ];

  programs.zsh.enable = true;
}
