{ inputs, ... }:
let
  modulePaths = inputs.nixpkgs.lib.collect builtins.isPath (
    inputs.haumea.lib.load {
      src = ../modules;
      loader = inputs.haumea.lib.loaders.path;
    }
  );
in
{
  imports = [
    inputs.flake-parts.flakeModules.modules
  ]
  ++ modulePaths;
}
