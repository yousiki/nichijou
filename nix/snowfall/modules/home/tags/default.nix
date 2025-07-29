# Define the tags option.
{
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
}
