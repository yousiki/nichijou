# Necessary packages for darwin.
{ lib, ... }:
{
  imports = [ (lib.snowfall.fs.get-file "nix/modules/common/packages/default.nix") ];

  programs = {
    bash.enable = true; # programs.bash.enable on NixOS is deprecated.
    man.enable = true;
  };
}
