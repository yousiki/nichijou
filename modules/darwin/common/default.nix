# Import all common modules as darwin module.
{ lib, ... }:
{
  imports = lib.snowfall.fs.get-default-nix-files-recursive (
    lib.snowfall.fs.get-file "modules/common"
  );
}
