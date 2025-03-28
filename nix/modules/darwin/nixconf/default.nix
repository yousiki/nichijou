# Nix configurations for darwin.
{
  lib,
  ...
}: {
  imports = [
    (lib.snowfall.fs.get-file
      "nix/modules/common/nixconf/default.nix")
  ];

  nix.nixPath = ["darwin=/etc/nix/inputs/darwin"];
}
