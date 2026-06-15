{pkgs, ...}: {
  imports = [
    ./programs/aliyun-cli.nix
    ./programs/ccstatusline.nix
    ./programs/claude-code.nix
    ./programs/cliproxyapi.nix
    ./programs/codex.nix
    ./programs/git.nix
    ./programs/helix.nix
    ./programs/herdr.nix
    ./programs/mcp-servers.nix
    ./programs/mole.nix
    ./programs/opencode.nix
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
  programs.gitui.enable = true;
  programs.herdr.enable = true;
  programs.lazydocker.enable = true;
  programs.lazygit.enable = true;
  programs.mcfly.enable = true;
  programs.nh.enable = true;
  programs.ripgrep.enable = true;
  programs.tmux.enable = true;
  programs.yazi.enable = true;
  programs.zellij.enable = true;
}
