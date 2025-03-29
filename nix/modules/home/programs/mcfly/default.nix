{
  lib,
  namespace,
  config,
  ...
}:
let
  cfg = config.${namespace}.programs.mcfly;
in
{
  options.${namespace}.programs.mcfly = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable mcfly.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.mcfly = {
      enable = true;
      enableBashIntegration = true;
      # FIXME: uncomment when zsh integration is fixed
      # enableZshIntegration = true;
      enableFishIntegration = true;
      fzf.enable = true;
      fuzzySearchFactor = 3;
    };
  };
}
