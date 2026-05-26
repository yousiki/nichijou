{ flake, hostName, ... }:

{
  imports = [
    flake.darwinModules.common
    flake.darwinModules.nix
    flake.darwinModules.homebrew
  ];

  networking.hostName = hostName;

  nixpkgs.hostPlatform = "aarch64-darwin";

  system.primaryUser = "yousiki";

  users.users.yousiki = {
    home = "/Users/yousiki";
  };

  system.configurationRevision = flake.rev or flake.dirtyRev or null;

  system.stateVersion = 6;
}
