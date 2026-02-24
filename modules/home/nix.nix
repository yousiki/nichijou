{
  config,
  pkgs,
  lib,
  flake,
  ...
}: {
  # To use the `nix` from `inputs.nixpkgs` on templates using the standalone `home-manager` template

  # `nix.package` is already set if on `NixOS` or `nix-darwin`.
  # TODO: Avoid setting `nix.package` in two places. Does https://github.com/juspay/nixos-unified-template/issues/93 help here?
  nix.package = lib.mkDefault pkgs.nix;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    # Up-to-date Claude Code package
    flake.inputs.claude-code.overlays.default
  ];

  home.packages = [
    config.nix.package
  ];
}
