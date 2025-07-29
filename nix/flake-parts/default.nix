{ flake-parts, ... }@inputs:
flake-parts.lib.mkFlake { inherit inputs; } {
  systems = import inputs.default-systems;

  imports = [
    ./devshells.nix # shell environments
    ./formatter.nix # code formatting
  ];
}
