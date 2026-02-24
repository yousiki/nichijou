{inputs, ...}: {
  imports = [inputs.treefmt-nix.flakeModule];

  perSystem = _: {
    treefmt = {
      projectRootFile = "flake.nix";
      # Nix
      programs.alejandra.enable = true;
      programs.deadnix.enable = true;
      programs.statix.enable = true;
      # JSON / JSONC
      programs.biome.enable = true;
    };
  };
}
