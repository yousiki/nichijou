# Common modules that applied to all systems (both NixOS and nix-darwin)
{ lib, ... }:
{
  imports = lib.map lib.snowfall.fs.get-file [
    "modules/common/fonts/default.nix"
    "modules/common/home-manager/default.nix"
    "modules/common/nix/default.nix"
    "modules/common/shell/default.nix"
    "modules/common/sshkeys/default.nix"
    "modules/common/tailscale/default.nix"
  ];
}
