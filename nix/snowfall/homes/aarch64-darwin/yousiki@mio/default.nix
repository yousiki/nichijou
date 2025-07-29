{ lib, ... }:
{
  nichijou.tags = import (lib.snowfall.fs.get-file "tags/mio.nix");
}
