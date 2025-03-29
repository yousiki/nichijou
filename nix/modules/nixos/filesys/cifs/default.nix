{
  lib,
  config,
  namespace,
  ...
}:
let
  mkCifs = _name: args: {
    inherit (args) device;
    fsType = "cifs";
    options = [
      "noauto"
      "x-systemd.automount"
      "x-systemd.idle-timeout=60"
      "x-systemd.device-timeout=5s"
      "x-systemd.mount-timeout=5s"
      "noperm"
      "credentials=${args.credentials}"
    ];
  };

  cfg = config.${namespace}.filesys.cifs;
in
{
  options.${namespace}.filesys.cifs = {
    enable = lib.mkEnableOption "Whether to enable cifs.";

    fileSystems = lib.mkOption {
      default = { };
      example = lib.literalExpression ''
        {
          "/mnt/share" = {
            device = "example.com/share";
            credentials = "/etc/credentials";
          };
        }
      '';
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
      description = lib.mdDoc "The cifs file systems to mount.";
    };
  };

  config = lib.mkIf cfg.enable { fileSystems = lib.mapAttrs mkCifs cfg.fileSystems; };
}
