{
  config,
  lib,
  namespace,
  ...
}:
{
  options.${namespace}.virtualisation = {
    enable = lib.mkEnableOption "Virtualisation";
  };

  config = lib.mkIf config.${namespace}.virtualisation.enable {
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
  };
}
