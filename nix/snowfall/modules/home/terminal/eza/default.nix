{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
lib.mkIf (builtins.elem "terminal" config.${namespace}.tags) {
  programs.eza = {
    enable = true;
    package = pkgs.eza;
    enableZshIntegration = true;
    extraOptions = [
      "--group-directories-first"
      "--header"
    ];
    icons = "auto";
    git = true;
  };

  home.shellAliases =
    let
      eza = lib.getExe config.programs.eza.package;
    in
    {
      tree = lib.mkForce "${eza} --tree --icons=always";
    };
}
