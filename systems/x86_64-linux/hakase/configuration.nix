{
  config,
  lib,
  pkgs,
  ...
}:
{
  networking = {
    # Set the hostname
    hostName = "hakase";
    # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
    # (the default) this is the recommended approach. When using systemd-networkd it's
    # still possible to use this option, but it's recommended to use it in conjunction
    # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
    useDHCP = lib.mkDefault true;
    # interfaces.enp2s0.useDHCP = lib.mkDefault true;
    # interfaces.wlo1.useDHCP = lib.mkDefault true;
  };

  services = {
    xserver.enable = true;
    displayManager.sddm.enable = true;
    displayManager.sddm.wayland.enable = true;
    desktopManager.plasma6.enable = true;
  };

  boot = {
    kernelPackages = pkgs.linuxPackagesFor (
      pkgs.buildLinux rec {
        version = "${modDirVersion}-bcachefs";
        modDirVersion = "6.16.0-rc2";
        src = pkgs.fetchgit {
          url = "https://evilpiepirate.org/git/bcachefs.git";
          rev = "37c2ea3bd694e1ea27fa9979013ec712030841a7";
          hash = "sha256-2ygTxdt/yXAogSGbSlSFJU8Ztsk0Apu3GQXzfmkppMI=";
        };
      }
    );
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    initrd = {
      availableKernelModules = [
        "vmd"
        "xhci_pci"
        "ahci"
        "nvme"
        "usbhid"
        "uas"
        "sd_mod"
      ];
      kernelModules = [ ];
    };
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
