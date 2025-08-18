{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.eza = {
    enable = lib.mkEnableOption "eza";
  };

  config = lib.mkIf config.${namespace}.programs.eza.enable {
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
  };
}
