# Necessary packages for darwin.
{
  pkgs,
  lib,
  ...
}: {
  imports = [
    (lib.snowfall.fs.get-file
      "modules/common/packages/default.nix")
  ];
}
