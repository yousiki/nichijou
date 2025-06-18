{
  config,
  lib,
  namespace,
  ...
}:
{
  options.${namespace}.programs.mcfly = {
    enable = lib.mkEnableOption "mcfly";
  };

  config =
    let
      cfg = config.${namespace}.programs.mcfly;
    in
    lib.mkIf cfg.enable {
      programs.mcfly = {
        enable = true;
        enableBashIntegration = true;
        enableZshIntegration = true;
        enableFishIntegration = true;
        fzf.enable = true;
        fuzzySearchFactor = 3;
      };
    };
}
