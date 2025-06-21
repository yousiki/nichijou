{
  config,
  lib,
  namespace,
  ...
}:
{
  options.${namespace}.suites.terminal = {
    enable = lib.mkEnableOption "Terminal Suite";
  };

  config =
    let
      cfg = config.${namespace}.suites.terminal;
    in
    lib.mkIf cfg.enable {
      nichijou.programs = {
        bat.enable = true;
        bottom.enable = true;
        btop.enable = true;
        direnv.enable = true;
        duf.enable = true;
        eza.enable = true;
        fzf.enable = true;
        gdu.enable = true;
        gh.enable = true;
        git.enable = true;
        gitui.enable = true;
        helix.enable = true;
        mcfly.enable = true;
        nh.enable = true;
        nix-index.enable = true;
        proxychains.enable = true;
        ssh.enable = true;
        starship.enable = true;
        tmux.enable = true;
        yazi.enable = true;
        zellij.enable = true;
        zoxide.enable = true;
        zsh.enable = true;
      };
    };
}
