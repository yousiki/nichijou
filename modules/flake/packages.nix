# Custom packages — accessible via 'nix build .#<name>'
# Also exposed as overlays.default via easyOverlay
{inputs, ...}: {
  imports = [
    inputs.flake-parts.flakeModules.easyOverlay
  ];

  perSystem = {
    config,
    pkgs,
    ...
  }: {
    overlayAttrs = {
      inherit (config.packages) mole;
    };

    packages.mole = pkgs.callPackage ../../pkgs/mole {};
  };
}
