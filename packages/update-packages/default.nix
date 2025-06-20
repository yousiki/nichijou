{ pkgs, ... }:
let
  # TODO: update nix-update-template to filter version tags for stable releases only
  nix-update-template =
    package:
    pkgs.writeShellScriptBin "update-${package}" ''
      ${pkgs.nix-update}/bin/nix-update \
        ${package} \
        --flake \
        --version-regex "^v?([0-9]+\\.[0-9]+\\.[0-9]+)$" \
        --override-filename packages/${package}/default.nix
    '';

  nix-update-packages-template =
    names:
    pkgs.writeShellScriptBin "update-packages" (
      pkgs.lib.concatStringsSep "\n" (
        pkgs.lib.map (
          name:
          let
            script = nix-update-template name;
          in
          "${script}/bin/update-${name}"
        ) names
      )
    );

  nix-update-packages-darwin = nix-update-packages-template [
    "alt-tab-macos"
    "easydict"
    "ice"
    "keepingyouawake"
  ];

  nix-update-packages-nixos = nix-update-packages-template [
    "zed-editor"
  ];
in
if pkgs.stdenv.isLinux then
  nix-update-packages-nixos
else if pkgs.stdenv.isDarwin then
  nix-update-packages-darwin
else
  throw "Unsupported platform: ${pkgs.stdenv.hostPlatform.system}"
