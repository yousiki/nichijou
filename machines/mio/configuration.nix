{
  self,
  ...
}:
{
  imports = with self.modules.darwin; [
    ./homebrew-casks.nix
    ./packages.nix
    home-manager
    homebrew
    homebrew-china
    nix-settings
    nix-settings-china
    shared
    user-yousiki
  ];

  home-manager.users.yousiki = {
    imports = with self.modules.home; [
      app.orbstack
      app.wezterm
      app.zed-editor
      awesome-shell
      catppuccin
      develop.nix
      develop.nodejs
      develop.python
      develop.rust
      shared
      user-yousiki
    ];
  };

  nixpkgs.hostPlatform = "aarch64-darwin";
}
