{ pkgs, fetchurl, ... }:
pkgs.alt-tab-macos.overrideAttrs (
  finalAttrs: _prevAttrs: {
    name = "alt-tab";
    version = "7.27.0";

    src = fetchurl {
      name = "AltTab-${finalAttrs.version}.zip";
      url = "https://github.com/lwouis/alt-tab-macos/releases/download/v${finalAttrs.version}/AltTab-${finalAttrs.version}.zip";
      hash = "sha256-jjtgpfKzLj2cAUvpjlC9STmp8EN3y+rdQVKJvTHzoXM=";
    };
  }
)
