{pkgs, ...}: {
  environment.systemPackages = [
    pkgs.vim
  ];

  fonts.packages = [
    pkgs.maple-mono.NF-CN-unhinted
  ];

  home-manager.backupFileExtension = "bak";

  programs.zsh.enable = true;
}
