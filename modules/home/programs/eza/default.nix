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

  config =
    let
      cfg = config.${namespace}.programs.eza;
    in
    lib.mkIf cfg.enable {
      programs.eza = {
        enable = true;
        package = pkgs.eza;
        enableBashIntegration = true;
        enableZshIntegration = true;
        enableNushellIntegration = true;
        enableFishIntegration = true;
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
