{
  config,
  lib,
  namespace,
  ...
}:
lib.mkIf (builtins.elem "terminal" config.${namespace}.tags) {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autocd = true;
    autosuggestion.enable = true;
    historySubstringSearch.enable = true;
    syntaxHighlighting.enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "gitignore"
        "history"
        "zsh-interactive-cd"
      ];
    };
    initContent = ''
      # Bindkey
      bindkey "\e[1;3D" backward-word
      bindkey "\e[1;3C" forward-word

      # Init orbstack
      if [[ -f ~/.orbstack/shell/init.zsh ]]; then
        source ~/.orbstack/shell/init.zsh 2>/dev/null || :
      fi
    '';
  };
}
