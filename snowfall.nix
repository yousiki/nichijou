inputs:
inputs.snowfall-lib.mkFlake {
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

  systems.modules = {
    nixos = with inputs; [
      nix-index-database.nixosModules.nix-index
    ];
    darwin = with inputs; [
      nix-index-database.darwinModules.nix-index
    ];
  };

  homes.modules = with inputs; [
    catppuccin.homeModules.catppuccin
    nix-index-database.homeModules.nix-index
  ];

  outputs-builder =
    channels:
    let
      treefmtEval = inputs.treefmt-nix.lib.evalModule channels.nixpkgs ./treefmt.nix;
    in
    {
      formatter = treefmtEval.config.build.wrapper;
      checks.treefmt = treefmtEval.config.build.check inputs.self;
    };
}
