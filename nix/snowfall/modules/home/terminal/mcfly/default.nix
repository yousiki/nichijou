{
  config,
  lib,
  namespace,
  ...
}:
lib.mkIf (builtins.elem "terminal" config.${namespace}.tags) {
  programs.mcfly = {
    enable = true;
    enableZshIntegration = true;
    fzf.enable = true;
    fuzzySearchFactor = 3;
  };
}
