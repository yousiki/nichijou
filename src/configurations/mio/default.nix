{ inputs, self, ... }:
let
  darwinModules = inputs.nixpkgs.lib.collect (mod: mod ? _class) self.modules.darwin;
in
{
  flake.darwinConfigurations.mio = inputs.nix-darwin.lib.darwinSystem {
    system = "aarch64-darwin";
    specialArgs = { inherit inputs; };
    modules = darwinModules ++ [
      ./manifest.nix
    ];
  };
}
