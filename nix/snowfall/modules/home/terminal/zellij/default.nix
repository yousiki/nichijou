{
  config,
  lib,
  namespace,
  ...
}:
lib.mkIf (builtins.elem "terminal" config.${namespace}.tags) {
  programs.zellij = {
    enable = true;
    settings = {
      show_startup_tips = false;
      show_release_notes = false;
    };
  };
}
