{ snowfall-lib, ... }@inputs:
snowfall-lib.mkFlake {
  inherit inputs;
  src = ./.;
  snowfall = {
    root = ./.;
    namespace = "nichijou";
  };
  channels-config = {
    allowUnfree = true;
  };
  overlays = with inputs; [
    brew-nix.overlays.default
    nix-index-database.overlays.nix-index
  ];
  homes.modules = with inputs; [
    catppuccin.homeModules.catppuccin
    nix-index-database.homeModules.nix-index
  ];
  systems.modules = {
    nixos = with inputs; [
      nix-index-database.nixosModules.nix-index
    ];
    darwin = with inputs; [
      nix-index-database.darwinModules.nix-index
    ];
  };
}
