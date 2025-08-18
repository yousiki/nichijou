# Enable tailscale service for all systems.
{
  config,
  lib,
  namespace,
  ...
}:
{
  options.${namespace}.services.tailscale = {
    enable = lib.mkEnableOption "Tailscale";
  };

  config = lib.mkIf config.${namespace}.services.tailscale.enable {
    services.tailscale.enable = true;
  };
}
