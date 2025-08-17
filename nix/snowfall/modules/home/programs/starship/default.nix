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

  config = lib.mkIf config.${namespace}.programs.starship.enable {
    programs.starship = {
      enable = true;
      enableZshIntegration = true;
      enableTransience = true;
      settings.format = "$all";
    };
  };
}
