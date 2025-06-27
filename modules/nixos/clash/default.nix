{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.clash = {
    enable = lib.mkEnableOption "clash";
  };

  config =
    let
      cfg = config.${namespace}.clash;
    in
    lib.mkIf cfg.enable {
      networking = {
        # Enable system proxy.
        proxy.default = "http://127.0.0.1:7890";
        proxy.noProxy = "127.0.0.1,localhost";
        # Open firewall for clash.
        firewall.allowedTCPPorts = [
          7890
          7891
        ];
      };

      services = {
        mihomo = {
          enable = true;
          webui = pkgs.metacubexd;
          configFile = "/etc/clash/config.yaml";
        };
      };
    };
}
