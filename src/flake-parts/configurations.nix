{ inputs, ... }:
let
  configurationPaths =
    inputs.nixpkgs.lib.collect (p: ((builtins.isPath p) && (builtins.baseNameOf p) == "default.nix"))
      (
        inputs.haumea.lib.load {
          src = ../configurations;
          loader = inputs.haumea.lib.loaders.path;
        }
      );
in
{
  imports = configurationPaths;
}
