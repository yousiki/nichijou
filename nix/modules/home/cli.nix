{pkgs, ...}: {
  imports = [
    ./programs/claude-code.nix
    ./programs/codex.nix
    ./programs/opencode.nix
    ./programs/mole.nix
    ./programs/cliproxyapi.nix
    ./programs/herdr.nix
    ./programs/git.nix
    ./programs/shell.nix
    ./programs/toolchains.nix
  ];

  home.packages = [
    pkgs.duf
    pkgs.fd
    pkgs.gdu
    pkgs.jq
    pkgs.just
  ];

  programs.btop.enable = true;
  programs.herdr.enable = true;
  programs.gitui.enable = true;
  programs.helix.enable = true;
  programs.lazydocker.enable = true;
  programs.lazygit.enable = true;
  programs.mcfly.enable = true;
  programs.ripgrep.enable = true;
  programs.tmux.enable = true;
  programs.yazi.enable = true;
  programs.zellij.enable = true;
}
