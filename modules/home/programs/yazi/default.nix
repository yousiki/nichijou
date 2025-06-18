{
  config,
  lib,
  namespace,
  ...
}:
{
  options.${namespace}.programs.yazi = {
    enable = lib.mkEnableOption "yazi";
  };

  config =
    let
      cfg = config.${namespace}.programs.yazi;
    in
    lib.mkIf cfg.enable {
      programs.yazi = {
        enable = true;
        enableBashIntegration = true;
        enableFishIntegration = true;
        enableNushellIntegration = true;
        enableZshIntegration = true;
      };
    };
}
