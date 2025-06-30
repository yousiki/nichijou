# Tailscale VPN
{
  config,
  lib,
  namespace,
  ...
}:
{
  options.${namespace}.tailscale = {
    enable = lib.mkEnableOption "Tailscale VPN";
  };

  config = lib.mkIf config.${namespace}.tailscale.enable {
    services.tailscale.enable = true;
  };
}
