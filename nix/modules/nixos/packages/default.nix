# Necessary packages for NixOS.
{ lib, ... }:
{
  imports = [ (lib.snowfall.fs.get-file "nix/modules/common/packages/default.nix") ];

  documentation.man.enable = true;
}
