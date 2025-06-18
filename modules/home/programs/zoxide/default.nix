{
  config,
  lib,
  namespace,
  ...
}:
{
  options.${namespace}.programs.zoxide = {
    enable = lib.mkEnableOption "zoxide";
  };

  config =
    let
      cfg = config.${namespace}.programs.zoxide;
    in
    lib.mkIf cfg.enable {
      programs.zoxide = {
        enable = true;
        enableBashIntegration = true;
        enableZshIntegration = true;
        enableFishIntegration = true;
        enableNushellIntegration = true;
      };
    };
}
