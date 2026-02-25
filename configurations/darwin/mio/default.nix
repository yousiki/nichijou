# nix-darwin configuration for mio (MacBook, aarch64-darwin)
# See /modules/darwin/* for shared system settings
{flake, ...}: let
  inherit (flake) inputs;
  inherit (inputs) self;
in {
  imports = [
    self.darwinModules.default
    self.darwinModules.sops
    ./homebrew.nix
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";
  networking.hostName = "mio";

  system.primaryUser = "yousiki";

  users.users.yousiki = {
    name = "yousiki";
    home = "/Users/yousiki";
  };

  home-manager.backupFileExtension = "before-home-manager";

  system.stateVersion = 6;
}
