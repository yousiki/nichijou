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
  ];
  homes.modules = with inputs; [
    catppuccin.homeModules.catppuccin
  ];
}
