{
  lib,
  namespace,
  config,
  ...
}: let
  cfg = config.${namespace}.programs.fzf;
in {
  options.${namespace}.programs.fzf = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable fzf.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.fzf = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
      tmux.enableShellIntegration = true;
    };
  };
}
