# Secrets management for Darwin.
{lib, ...}: {
  imports = [
    (lib.snowfall.fs.get-file
      "modules/common/secrets/default.nix")
  ];
}
