{ modulesPath, ... }:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./configuration.nix
    ./disk-configuration.nix
    ./hardware-configuration.nix
  ];

  nichijou = {
    sshkeys.enable = true;
  };
}
