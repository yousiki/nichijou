{
  config,
  lib,
  namespace,
  ...
}:
{
  options.${namespace}.programs.starship = {
    enable = lib.mkEnableOption "starship";
  };

  config =
    let
      cfg = config.${namespace}.programs.starship;
    in
    lib.mkIf cfg.enable {
      programs.starship = {
        enable = true;
        enableBashIntegration = true;
        enableZshIntegration = true;
        enableFishIntegration = true;
        enableNushellIntegration = true;
        enableTransience = true;
        settings.format = "$all";
      };
    };
}
