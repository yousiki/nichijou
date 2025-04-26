{
  lib,
  namespace,
  config,
  ...
}:
let
  cfg = config.${namespace}.programs.zsh;

  plugins =
    [
      "copyfile"
      "copypath"
      "docker"
      "git"
      "gitignore"
      "history"
      "python"
      "rust"
      "shell-proxy"
      "zsh-interactive-cd"
    ]
    ++ (lib.optional config.programs.fzf.enable "fzf")
    ++ (lib.optional config.programs.zoxide.enable "zoxide");
in
{
  options.${namespace}.programs.zsh = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable zsh.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      autocd = true;
      autosuggestion.enable = true;
      historySubstringSearch.enable = true;
      syntaxHighlighting.enable = true;
      oh-my-zsh = {
        enable = true;
        theme = "robbyrussell";
        inherit plugins;
      };
      initContent = ''
        bindkey "\e[1;3D" backward-word
        bindkey "\e[1;3C" forward-word

        if [[ -f ~/.orbstack/shell/init.zsh ]]; then
          source ~/.orbstack/shell/init.zsh 2>/dev/null || :
        fi
      '';
    };
  };
}
