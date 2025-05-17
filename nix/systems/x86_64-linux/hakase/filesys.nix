{ config, ... }:
{
  # Filesystems
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/d7bb32dc-4599-499c-913e-73660f0cf3c6";
      fsType = "bcachefs";
      options = [
        "defaults"
        "noatime"
        "nodiratime"
      ];
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/5764-78C1";
      fsType = "vfat";
    };
    "/mnt/data" = {
      device = "/dev/disk/by-uuid/1934f151-3a0b-4431-87bb-ee69ff9634da";
      fsType = "bcachefs";
      options = [
        "defaults"
        "nofail"
        "noatime"
        "nodiratime"
      ];
    };
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/d1772975-d75b-4efa-aed1-3cb602761b56"; }
    { device = "/dev/disk/by-uuid/9dc3e2ac-b63d-4dda-8b4c-7be566aa349a"; }
  ];

  nichijou.filesys = {
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
        "/mnt/satoshi/Downloads" = {
          device = "//satoshi.siki.moe/Downloads";
          credentials = config.sops.secrets."nas-satoshi-credentials.env".path;
        };
      };
    };
  };
}
