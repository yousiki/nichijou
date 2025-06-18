{
  config,
  lib,
  namespace,
  ...
}:
{
  options.${namespace}.programs.zsh = {
    enable = lib.mkEnableOption "zsh";
  };

  config =
    let
      cfg = config.${namespace}.programs.zsh;
    in
    lib.mkIf cfg.enable {
      programs.zsh = {
        enable = true;
        enableCompletion = true;
        autocd = true;
        autosuggestion.enable = true;
        historySubstringSearch.enable = true;
        syntaxHighlighting.enable = true;
        oh-my-zsh = {
          enable = true;
          plugins =
            [
              "git"
              "gitignore"
              "history"
              "zsh-interactive-cd"
            ]
            ++ (lib.optional config.programs.fzf.enable "fzf")
            ++ (lib.optional config.programs.zoxide.enable "zoxide");
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
    };
}
