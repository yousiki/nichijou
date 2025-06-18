{
  config,
  lib,
  namespace,
  ...
}:
{
  options.${namespace}.programs.fzf = {
    enable = lib.mkEnableOption "fzf";
  };

  config =
    let
      cfg = config.${namespace}.programs.fzf;
    in
    lib.mkIf cfg.enable {
      programs.fzf = {
        enable = true;
        enableBashIntegration = true;
        enableZshIntegration = true;
        enableFishIntegration = true;
        tmux.enableShellIntegration = true;
      };
    };
}
