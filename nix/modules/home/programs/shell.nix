{ config, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
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
    enableZshIntegration = true;
    git = true;
    icons = "auto";
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };
}
