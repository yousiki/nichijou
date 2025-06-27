{
  config,
  lib,
  namespace,
  ...
}:
{
  options.${namespace}.tailscale = {
    enable = lib.mkEnableOption "tailscale";
  };

  config = lib.mkIf config.${namespace}.tailscale.enable {
    services.tailscale.enable = true;
  };
}
