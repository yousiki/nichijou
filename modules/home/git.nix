{
  config,
  pkgs,
  ...
}: {
  home.shellAliases = {
    g = "git";
    lg = "lazygit";
  };

  # https://nixos.asia/en/git
  programs = {
    git = {
      enable = true;
      ignores = [
        "*~"
        "*.swp"
      ];
      settings = {
        user = {
          name = config.me.fullname;
          inherit (config.me) email;
        };
        alias.ci = "commit";
        init.defaultBranch = "main";
        push.autoSetupRemote = true;
        pull.rebase = true;
        rerere.enabled = true;
      };
    };

    # Better git diff with syntax highlighting
    delta = {
      enable = true;
      enableGitIntegration = true;
    };

    # GitHub CLI
    gh = {
      enable = true;
      gitCredentialHelper.enable = true;
      extensions = with pkgs; [
        gh-dash
        gh-poi
        gh-notify
        gh-s
      ];
    };

    lazygit.enable = true;
    gitui.enable = true;
  };
}
