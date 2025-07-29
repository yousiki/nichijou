{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
lib.mkIf (builtins.elem "terminal" config.${namespace}.tags) {
  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
    symlinkToCacheHome = true; # Symlink nix-index-database to ~/.cache/nix-index
  };
  home.packages = with pkgs; [
    comma
  ];
}
