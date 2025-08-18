{
  config,
  lib,
  namespace,
  ...
}:
{
  options.${namespace}.suites.terminal = {
    enable = lib.mkEnableOption "terminal suite";
  };

  config = lib.mkIf config.${namespace}.suites.terminal.enable {
    ${namespace}.programs = builtins.listToAttrs (
      builtins.map
        (program: {
          name = program;
          value = {
            enable = true;
          };
        })
        [
          "bat"
          "btop"
          "curl"
          "direnv"
          "duf"
          "eza"
          "fzf"
          "gdu"
          "gh"
          "git"
          "gitui"
          "helix"
          "mcfly"
          "neovim"
          "nix-index"
          "starship"
          "tmux"
          "wget"
          "yazi"
          "zellij"
          "zoxide"
          "zsh"
        ]
    );
  };
}
