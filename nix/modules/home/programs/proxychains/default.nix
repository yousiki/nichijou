{
  lib,
  pkgs,
  namespace,
  config,
  ...
}:
let
  cfg = config.${namespace}.programs.proxychains;
in
{
  options.${namespace}.programs.proxychains = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable proxychains.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.proxychains-ng;
      description = "The proxychains package to use.";
    };

    proxyDNS = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Proxy DNS requests - no leak for DNS data.";
    };

    remoteDNSSubnet = lib.mkOption {
      type = lib.types.str;
      default = "224";
      description = "Set the class A subnet used for the internal remote DNS mapping.";
    };

    tcpReadTimeOut = lib.mkOption {
      type = lib.types.int;
      default = 15000;
      description = "TCP read time out in milliseconds.";
    };

    tcpConnectTimeOut = lib.mkOption {
      type = lib.types.int;
      default = 8000;
      description = "TCP connect time out in milliseconds.";
    };

    chainType = lib.mkOption {
      type = lib.types.enum [
        "dynamic"
        "strict"
        "random"
      ];
      default = "dynamic";
      description = "Chain type: dynamic, strict, or random.";
    };

    quietMode = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Quiet mode (no output from library).";
    };

    proxies = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            type = lib.mkOption {
              type = lib.types.enum [
                "http"
                "socks4"
                "socks5"
              ];
              description = "Proxy type.";
            };
            host = lib.mkOption {
              type = lib.types.str;
              description = "Proxy host/IP address.";
            };
            port = lib.mkOption {
              type = lib.types.port;
              description = "Proxy port.";
            };
            username = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Proxy username (optional).";
            };
            password = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Proxy password (optional).";
            };
          };
        }
      );
      default = [
        {
          type = "http";
          host = "127.0.0.1";
          port = 7890;
        }
      ];
      description = "List of proxy configurations.";
    };

    localnet = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "127.0.0.0/255.0.0.0"
        "10.0.0.0/255.0.0.0"
        "172.16.0.0/255.240.0.0"
        "192.168.0.0/255.255.0.0"
      ];
      description = "Localnet exclusion list - addresses that will be accessed directly.";
    };

    enableAlias = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable the proxychains alias.";
    };
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = [ cfg.package ];
      sessionVariables = {
        PROXYCHAINS_CONF_FILE = "${config.xdg.configHome}/proxychains/proxychains.conf";
      };
      shellAliases =
        let
          bin = "${cfg.package}/bin/proxychains4";
        in
        lib.mkIf cfg.enableAlias {
          pc = bin;
          proxychains = bin;
        };
    };

    xdg.configFile."proxychains/proxychains.conf".text = ''
      # proxychains.conf VER 4.x
      #
      # HTTP, SOCKS4a, SOCKS5 tunneling proxifier with DNS.
      #

      # The option below identifies how the ProxyList is treated.
      # only one option should be uncommented at time,
      # otherwise the last appearing option will be accepted
      #
      #dynamic_chain
      #
      # Dynamic - Each connection will be done via chained proxies
      # all proxies chained in the order as they appear in the list
      # at least one proxy must be online to play in chain
      # (dead proxies are skipped)
      # otherwise EINTR is returned to the app
      #
      #strict_chain
      #
      # Strict - Each connection will be done via chained proxies
      # all proxies chained in the order as they appear in the list
      # all proxies must be online to play in chain
      # otherwise EINTR is returned to the app
      #
      #round_robin_chain
      #
      # Round Robin - Each connection will be done via chained proxies
      # of chain_len length
      # all proxies chained in the order as they appear in the list
      # at least one proxy must be online to play in chain
      # (dead proxies are skipped).
      # the start of the current proxy chain is the proxy after the last
      # proxy in the previously invoked proxy chain.
      # if the end of the proxy chain is reached while looking for proxies
      # start at the beginning again.
      # otherwise EINTR is returned to the app
      # These semantics are not guaranteed in a multithreaded environment.
      #
      #random_chain
      #
      # Random - Each connection will be done via random proxy
      # (or proxy chain, see  chain_len) from the list.
      # this option is good to test your IDS :)

      # Make sense only if random_chain or round_robin_chain
      #chain_len = 2

      # Quiet mode (no output from library)
      ${lib.optionalString cfg.quietMode "quiet_mode"}

      ## Proxy DNS requests - no leak for DNS data
      ${lib.optionalString cfg.proxyDNS "proxy_dns"}

      # set the class A subnet used for the internal remote DNS mapping
      # we use the reserved 224.x.x.x range by default,
      # if the proxified app does a DNS request, we will return an IP from that range.
      # on further accesses to this ip we will send the saved DNS name to the proxy.
      # in case some control-freak app checks the returned ip, and denies to
      # connect, you can use another subnet, e.g. 10.x.x.x or 127.x.x.x.
      # of course you should make sure that the proxified app does not need
      # *real* access to this subnet.
      # i.e. dont use the same subnet then in the localnet section
      remote_dns_subnet ${cfg.remoteDNSSubnet}

      # Some timeouts in milliseconds
      tcp_read_time_out ${toString cfg.tcpReadTimeOut}
      tcp_connect_time_out ${toString cfg.tcpConnectTimeOut}

      ### Examples for localnet exclusion
      ## localnet ranges will *not* use a proxy to connect.
      ## Exclude connections to 192.168.1.0/24 with port 80
      # localnet 192.168.1.0:80/255.255.255.0

      ## Exclude connections to 192.168.100.0/24
      # localnet 192.168.100.0/255.255.255.0

      ## Exclude connections to ANYwhere with port 80
      # localnet 0.0.0.0:80/0.0.0.0

      ## RFC5735 Loopback address range
      ## if you enable this, you have to make sure remote_dns_subnet is not 127
      ## you'll need to enable it if you want to use an application that
      ## connects to localhost.
      # localnet 127.0.0.0/255.0.0.0

      ## RFC1918 Private Address Ranges
      # localnet 10.0.0.0/255.0.0.0
      # localnet 172.16.0.0/255.240.0.0
      # localnet 192.168.0.0/255.255.0.0

      ${lib.concatMapStringsSep "\n" (net: "localnet ${net}") cfg.localnet}

      ${cfg.chainType}_chain

      [ProxyList]
      # add proxy here ...
      # meanwile
      # defaults set to "tor"
      ${lib.concatMapStringsSep "\n" (
        proxy:
        "${proxy.type} ${proxy.host} ${toString proxy.port}"
        + lib.optionalString (
          proxy.username != null && proxy.password != null
        ) " ${proxy.username} ${proxy.password}"
      ) cfg.proxies}
    '';
  };
}
