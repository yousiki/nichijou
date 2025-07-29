{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
lib.mkIf (builtins.elem "terminal" config.${namespace}.tags) {
  home.packages = with pkgs; [ duf ];
}
