{ modulesPath, ... }:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./configuration.nix
    ./disko-configuration.nix
    ./hardware-configuration.nix
  ];

  nichijou = {
    shell.enable = true;
    sshkeys.enable = true;
  };
}
