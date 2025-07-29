{
  config,
  lib,
  namespace,
  ...
}:
lib.mkIf (builtins.elem "terminal" config.${namespace}.tags) {
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
  };
}
