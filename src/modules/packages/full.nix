_: {
  flake.modules =
    let
      packages =
        pkgs: with pkgs; [
          bat
          btop
          curl
          duf
          eza
          fd
          fzf
          gdu
          gh
          git
          gitui
          helix
          htop
          jq
          neovim
          ripgrep
          rsync
          tmux
          vim
          wget
          zellij
          zoxide
        ];

      cond =
        { config, ... }:
        let
          tags = config.manifest.tags or [ ];
        in
        !(builtins.elem "minimized" tags);

      commonModule =
        { lib, pkgs, ... }@args:
        lib.mkIf (cond args) {
          environment.systemPackages = packages pkgs;
        };

      homeModule =
        { lib, pkgs, ... }@args:
        lib.mkIf (cond args) {
          home.packages = packages pkgs;
        };
    in
    {
      nixos.packages-full = commonModule;
      darwin.packages-full = commonModule;
      home.packages-full = homeModule;
    };
}
