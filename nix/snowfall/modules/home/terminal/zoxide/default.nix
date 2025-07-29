{
  config,
  lib,
  namespace,
  ...
}:
lib.mkIf (builtins.elem "terminal" config.${namespace}.tags) {
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
}
