{ lib, namespace, ... }:
{
  networking = {
    hostName = "mio";
    computerName = "yousiki-mio";
  };

  ${namespace}.tags = import (lib.snowfall.fs.get-file "tags/mio.nix");
}
