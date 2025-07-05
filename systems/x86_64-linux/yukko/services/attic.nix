{ lib, config, ... }:
{
  services = {
    atticd = {
      enable = true;
      environmentFile = config.sops.secrets."atticd.env".path;
      settings = {
        listen = "[::]:8080";
        database = {
          url = "/var/lib/postgresql";
        };
        storage = {
          type = "s3";
          endpoint = "https://3ba1aaf889ad9e15eebee459ff361919.r2.cloudflarestorage.com/attic";
        };
        chunking =
          let
            MiB = 1048576;
          in
          {
            nar-size-threshold = 32 * MiB;
            min-size = 16 * MiB;
            avg-size = 32 * MiB;
            max-size = 128 * MiB;
          };
        compression = {
          type = "zstd";
          level = 22;
        };
        garbage-collection = {
          interval = "12 hours";
        };
      };
    };
    postgresql = {
      enable = true;
      ensureDatabases = [ "attic" ];
      ensureUsers = [
        {
          name = "attic";
        }
      ];
      authentication = lib.mkOverride 10 ''
        #type database  DBuser  auth-method
        local all       all     trust
      '';
    };
    traefik.dynamicConfigOptions = {
      http.routers = {
        attic = {
          entryPoints = [
            "http"
            "https"
          ];
          rule = "Host(`attic.siki.moe`)";
          service = "attic";
        };
      };
      http.services = {
        attic.loadBalancer.servers = [
          { url = "http://localhost:8080"; }
        ];
      };
    };
  };
  sops.secrets."atticd.env" = {
    sopsFile = lib.snowfall.fs.get-file "secrets/atticd.env";
    format = "dotenv";
    key = "";
  };
}
