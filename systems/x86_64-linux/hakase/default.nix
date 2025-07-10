{ modulesPath, ... }:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./configuration.nix
    ./hardware-configuration.nix
  ];

  nichijou = {
    fonts.enable = true;
    mihomo.enable = true;
    nix.enableMirror = true;
    nvidia.enable = true;
    shell.enable = true;
    sshkeys.enable = true;
    tailscale.enable = true;
    virtualisation.enable = true;
  };
}
