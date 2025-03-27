{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  networking = {
    # Set the hostname
    hostName = "hakase";
    # Open firewall for docker swarm
    firewall = {
      allowedTCPPorts = [
        2376
        2377
        7946
      ];
      allowedUDPPorts = [
        7946
        4789
      ];
    };
    # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
    # (the default) this is the recommended approach. When using systemd-networkd it's
    # still possible to use this option, but it's recommended to use it in conjunction
    # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
    useDHCP = lib.mkDefault true;
    # interfaces.enp2s0.useDHCP = lib.mkDefault true;
    # interfaces.wlo1.useDHCP = lib.mkDefault true;
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  boot.initrd.availableKernelModules = ["vmd" "xhci_pci" "ahci" "nvme" "usbhid" "uas" "sd_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel"];
  boot.extraModulePackages = [];

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/d7bb32dc-4599-499c-913e-73660f0cf3c6";
      fsType = "bcachefs";
      options = ["noatime"];
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/5764-78C1";
      fsType = "vfat";
    };
  };

  swapDevices = [
    {device = "/dev/disk/by-uuid/d1772975-d75b-4efa-aed1-3cb602761b56";}
    {device = "/dev/disk/by-uuid/9dc3e2ac-b63d-4dda-8b4c-7be566aa349a";}
  ];

  # Enable docker and podman
  virtualisation = {
    docker = {
      enable = true;
      rootless.enable = true;
      autoPrune.enable = true;
    };
    podman = {
      enable = true;
      autoPrune.enable = true;
    };
  };

  services = {
    xserver.enable = true;
    displayManager.sddm.enable = true;
    displayManager.sddm.wayland.enable = true;
    desktopManager.plasma6.enable = true;
    tailscale.enable = true;
  };

  nichijou = {
    system = {
      filesys = {
        bcachefs = {
          enable = true;
          fileSystems."/mnt/data" = {
            devices = ["/dev/nvme0n1p3" "/dev/sda1" "/dev/sdb1"];
            options = ["noatime"];
          };
        };
        cifs = {
          enable = true;
          fileSystems = {
            "/mnt/mck/home" = {
              device = "//nas-mck-v4.siki.moe/home";
              credentials = config.sops.secrets."nas-mck-credentials.env".path;
            };
            "/mnt/mck/share" = {
              device = "//nas-mck-v4.siki.moe/share";
              credentials = config.sops.secrets."nas-mck-credentials.env".path;
            };
            "/mnt/yyp/home" = {
              device = "//nas-yyp-v4.siki.moe/home";
              credentials = config.sops.secrets."nas-yyp-credentials.env".path;
            };
            "/mnt/yyp/share" = {
              device = "//nas-yyp-v4.siki.moe/share";
              credentials = config.sops.secrets."nas-yyp-credentials.env".path;
            };
            "/mnt/satoshi/Container" = {
              device = "//satoshi.siki.moe/Container";
              credentials = config.sops.secrets."nas-satoshi-credentials.env".path;
            };
            "/mnt/satoshi/Documents" = {
              device = "//satoshi.siki.moe/Documents";
              credentials = config.sops.secrets."nas-satoshi-credentials.env".path;
            };
            "/mnt/satoshi/Downloads" = {
              device = "//satoshi.siki.moe/Downloads";
              credentials = config.sops.secrets."nas-satoshi-credentials.env".path;
            };
            "/mnt/satoshi/Music" = {
              device = "//satoshi.siki.moe/Music";
              credentials = config.sops.secrets."nas-satoshi-credentials.env".path;
            };
            "/mnt/satoshi/Photos" = {
              device = "//satoshi.siki.moe/Photos";
              credentials = config.sops.secrets."nas-satoshi-credentials.env".path;
            };
            "/mnt/satoshi/Videos" = {
              device = "//satoshi.siki.moe/Videos";
              credentials = config.sops.secrets."nas-satoshi-credentials.env".path;
            };
          };
        };
      };
      gpu.nvidia.enable = true;
      proxy.enable = true;
      secrets.enable = true;
    };
  };

  # Use /mnt/data/cache/uv for uv caching
  environment.sessionVariables.UV_CACHE_DIR = "/mnt/data/cache/uv";

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
