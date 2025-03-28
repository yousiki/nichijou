# Nix configurations for darwin.
{
  pkgs,
  lib,
  ...
}: {
  imports = [
    (lib.snowfall.fs.get-file
      "modules/common/nixconf/default.nix")
  ];

  nix.nixPath = ["darwin=/etc/nix/inputs/darwin"];
}
