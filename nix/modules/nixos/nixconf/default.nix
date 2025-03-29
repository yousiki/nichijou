# Nix configurations for NixOS.
{ lib, ... }:
{
  imports = [ (lib.snowfall.fs.get-file "nix/modules/common/nixconf/default.nix") ];
}
