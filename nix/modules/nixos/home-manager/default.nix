# Home-manager configurations for Darwin.
{ lib, ... }:
{
  imports = [
    (lib.snowfall.fs.get-file "nix/modules/common/home-manager/default.nix")
  ];
}
