# Define the tags option and automatically import tags based on the hostname.
{
  config,
  lib,
  namespace,
  ...
}:
{
  options.${namespace}.tags = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    description = "Tags for the system, used to enable or disable features.";
    example = [
      "desktop"
    ];
  };

  config = {
    ${namespace}.tags =
      let
        hostname = config.networking.hostName;
        path = lib.snowfall.fs.get-file "tags/${hostname}.nix";
      in
      lib.optionals (builtins.pathExists path) (import path);
  };
}
