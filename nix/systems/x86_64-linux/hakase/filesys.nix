{ config, ... }:
{
  # Filesystems
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/d7bb32dc-4599-499c-913e-73660f0cf3c6";
      fsType = "bcachefs";
      options = [ "noatime" ];
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/5764-78C1";
      fsType = "vfat";
    };
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/d1772975-d75b-4efa-aed1-3cb602761b56"; }
    { device = "/dev/disk/by-uuid/9dc3e2ac-b63d-4dda-8b4c-7be566aa349a"; }
  ];

  nichijou.filesys = {
    bcachefs = {
      enable = true;
      fileSystems."/mnt/data" = {
        devices = [
          "/dev/nvme0n1p3"
          "/dev/sda1"
          "/dev/sdb1"
        ];
        options = [ "noatime" ];
      };
    };
    cifs = {
      enable = true;
      fileSystems = {
        # NAS MCK
        "/mnt/mck/home" = {
          device = "//nas-mck-v4.siki.moe/home";
          credentials = config.sops.secrets."nas-mck-credentials.env".path;
        };
        "/mnt/mck/share" = {
          device = "//nas-mck-v4.siki.moe/share";
          credentials = config.sops.secrets."nas-mck-credentials.env".path;
        };
        # NAS YYP
        "/mnt/yyp/home" = {
          device = "//nas-yyp-v4.siki.moe/home";
          credentials = config.sops.secrets."nas-yyp-credentials.env".path;
        };
        "/mnt/yyp/share" = {
          device = "//nas-yyp-v4.siki.moe/share";
          credentials = config.sops.secrets."nas-yyp-credentials.env".path;
        };
        # NAS satoshi
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
}
