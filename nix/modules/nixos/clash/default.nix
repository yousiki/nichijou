{
  lib,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.clash;
in
{
  options.${namespace}.clash = {
    enable = lib.mkEnableOption "Whether to enable system proxy via clash";
  };

  config = lib.mkIf cfg.enable {
    networking = {
      # Enable system proxy.
      proxy.default = "http://127.0.0.1:7890";
      proxy.noProxy = "127.0.0.1,localhost,siki.moe";
      # Open firewall for clash.
      firewall.allowedTCPPorts = [
        7890
        7891
      ];
    };

    services = {
      # Enable clash (mihomo, a.k.a clash-meta).
      mihomo = {
        enable = true;
        configFile = config.sops.secrets."clash.yaml".path;
      };
    };
  };
}
