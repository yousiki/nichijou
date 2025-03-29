# NixOS module to mount bcachefs volumes with multiple devices
{
  lib,
  config,
  pkgs,
  namespace,
  ...
}:
let
  bcachefsVolume = _: {
    options = {
      devices = lib.mkOption {
        type = lib.types.listOf lib.types.path;
        description = lib.mdDoc "The devices to use for the filesystem.";
      };

      options = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = lib.mdDoc "Additional options to pass to `mount`.";
      };
    };
  };

  pathToString =
    path: lib.removePrefix "-" (lib.replaceStrings [ "/" ] [ "-" ] (builtins.toString path));

  mkUnit =
    mountPoint: mountOptions:
    let
      inherit (mountOptions) devices options;
      deviceTargets = lib.pipe devices [
        (builtins.map pathToString)
        (builtins.map (lib.removePrefix "-"))
        (builtins.map (device: "${device}.device"))
      ];
      concatDevices = lib.concatStringsSep ":" (builtins.map builtins.toString devices);
      concatOptions = lib.concatStringsSep "," options;
    in
    {
      description = "Mount bcachefs ${mountPoint}";
      bindsTo = deviceTargets;
      after = deviceTargets ++ [ "local-fs-pre.target" ];
      before = [
        "umount.target"
        "local-fs.target"
      ];
      conflicts = [ "umount.target" ];
      wantedBy = [ "local-fs.target" ];
      unitConfig = {
        RequiresMountsFor = mountPoint;
        DefaultDependencies = false;
      };
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.util-linux}/bin/mount -t bcachefs -o ${concatOptions} ${concatDevices} ${mountPoint}";
        ExecStop = "${pkgs.util-linux}/umount ${mountPoint}";
      };
    };

  cfg = config.${namespace}.filesys.bcachefs;
in
{
  options.${namespace}.filesys.bcachefs = {
    enable = lib.mkEnableOption "Whether to enable bcachefs.";

    fileSystems = lib.mkOption {
      default = { };
      example = lib.literalExpression ''
        {
          "/data" = {
            device = [ "/dev/sda1" "/dev/sdb1" ];
            options = [ "noatime" ];
          };
        }
      '';
      type = lib.types.attrsOf (lib.types.submodule [ bcachefsVolume ]);
    };
  };

  config = lib.mkIf cfg.enable {
    boot.supportedFilesystems = [ "bcachefs" ];

    environment.systemPackages = with pkgs; [ bcachefs-tools ];

    systemd = {
      packages = with pkgs; [ bcachefs-tools ];
      services = lib.mapAttrs' (
        name: value: lib.nameValuePair "mount-bcachefs-${pathToString name}" (mkUnit name value)
      ) cfg.fileSystems;
    };
  };
}
