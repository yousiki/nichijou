{
  lib,
  namespace,
  format,
  config,
  ...
}:
let
  cfg = config.${namespace}.programs.starship;
in
{
  options.${namespace}.programs.starship = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable starship.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.starship = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
      enableIonIntegration = true;
      enableNushellIntegration = true;
      enableTransience = true;
      settings.format = "$all";
    };
  };
}
