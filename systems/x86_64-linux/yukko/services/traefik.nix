_: {
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.traefik = {
    enable = true;
    staticConfigOptions = {
      entryPoints = {
        http = {
          address = ":80";
          asDefault = true;
          http.redirections.entrypoint = {
            to = "https";
            scheme = "https";
          };
        };
        https = {
          address = ":443";
          asDefault = true;
        };
      };
      tls.certificates = [
        {
          certFile = "/etc/ssl/cloudflare/origin.pem";
          keyFile = "/etc/ssl/cloudflare/origin.key";
        }
      ];
      log = {
        level = "INFO";
        format = "json";
      };
    };
  };
}
