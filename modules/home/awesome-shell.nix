{
  pkgs,
  ...
}:
{
  programs.zsh = {
    enable = true;
    autosuggestion = {
      enable = true;
      strategy = [
        "history"
        "completion"
      ];
    };
    historySubstringSearch.enable = true;
    syntaxHighlighting = {
      enable = true;
      highlighters = [
        "main"
        "brackets"
        "cursor"
        "root"
      ];
    };
    autocd = true;
    enableCompletion = true;
    oh-my-zsh = {
      enable = true;
      plugins = [
        "brew"
        "copyfile"
        "copypath"
        "docker"
        "docker-compose"
        "git"
        "zsh-interactive-cd"
      ];
    };
  };

  programs.btop = {
    enable = true;
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    git = true;
    icons = "auto";
    colors = "auto";
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
    delta.enable = true;
    extraConfig = {
      pull.rebase = true;
      init.defaultBranch = "main";
    };
  };

  programs.gitui = {
    enable = false; # temporarily disabled due to package broken
  };

  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
    settings.editor = "${pkgs.neovim}/bin/nvim";
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [ "~/.ssh/config.local" ];
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.tmux = {
    enable = true;
    clock24 = true;
    mouse = true;
  };

  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zellij = {
    enable = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  home.packages = with pkgs; [
    duf
    gdu
    rsync
  ];
}
