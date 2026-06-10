{config, ...}: {
  home.shell.enableZshIntegration = true;

  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
    completionInit = ''
      autoload -Uz compinit
      mkdir -p "${config.xdg.cacheHome}/zsh"
      compinit -d "${config.xdg.cacheHome}/zsh/zcompdump"
    '';
    history.path = "${config.xdg.stateHome}/zsh/history";
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
  };

  programs.bat.enable = true;

  programs.eza = {
    enable = true;
    git = true;
    icons = "auto";
  };

  programs.fzf = {
    enable = true;
  };

  programs.zoxide = {
    enable = true;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.starship = {
    enable = true;
  };
}
