# Secrets management for Darwin.
{lib, ...}: {
  imports = [
    (lib.snowfall.fs.get-file
      "nix/modules/common/secrets/default.nix")
  ];
}
