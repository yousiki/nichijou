{
  config,
  lib,
  namespace,
  ...
}:
lib.mkIf (builtins.elem "terminal" config.${namespace}.tags) {
  programs.gitui = {
    enable = true;
  };
}
