{
  config,
  lib,
  namespace,
  ...
}:
lib.mkIf (builtins.elem "terminal" config.${namespace}.tags) {
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    enableTransience = true;
    settings.format = "$all";
  };
}
