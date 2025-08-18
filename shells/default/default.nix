{
  inputs,
  mkShell,
  pkgs,
  ...
}:
mkShell {
  packages = [
    inputs.flake-fmt.packages.${pkgs.system}.default
    pkgs.nh
    pkgs.nix-update
  ];
}
