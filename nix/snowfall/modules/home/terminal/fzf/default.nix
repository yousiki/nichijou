{
  config,
  lib,
  namespace,
  ...
}:
lib.mkIf (builtins.elem "terminal" config.${namespace}.tags) {
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
}
