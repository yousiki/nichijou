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

  config = lib.mkIf config.${namespace}.programs.mcfly.enable {
    programs.mcfly = {
      enable = true;
      enableZshIntegration = true;
      fzf.enable = true;
      fuzzySearchFactor = 3;
    };
  };
}
