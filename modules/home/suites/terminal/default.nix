{
  lib,
  namespace,
  config,
  ...
}: let
  cfg = config.${namespace}.suites.terminal;
in {
  options.${namespace}.suites.terminal = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable terminal suite.";
    };
  };

  config = lib.mkIf cfg.enable {
    ${namespace} = {
      programs = {
        terminal = {
          bat.enable = true;
          bottom.enable = true;
          btop.enable = true;
          comma.enable = true;
          direnv.enable = true;
          duf.enable = true;
          eza.enable = true;
          fzf.enable = true;
          gdu.enable = true;
          git.enable = true;
          mcfly.enable = false; # FIXME: Enable mcfly when zsh integration is fixed
          nh.enable = true;
          ssh.enable = true;
          starship.enable = true;
          tmux.enable = true;
          yazi.enable = true;
          zellij.enable = true;
          zoxide.enable = true;
          zsh.enable = true;
        };
      };
    };
  };
}
