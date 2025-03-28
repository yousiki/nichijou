# Necessary packages for darwin.
{
  lib,
  ...
}: {
  imports = [
    (lib.snowfall.fs.get-file
      "nix/modules/common/packages/default.nix")
  ];
}
