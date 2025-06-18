{ pkgs, fetchurl, ... }:
pkgs.alt-tab-macos.overrideAttrs (
  finalAttrs: _prevAttrs: {
    name = "alt-tab";
    version = "7.25.0";

    src = fetchurl {
      url = "https://github.com/lwouis/alt-tab-macos/releases/download/v${finalAttrs.version}/AltTab-${finalAttrs.version}.zip";
      hash = "sha256-e13en0fQHO0i49gP1zU6ms9TDMAwo1qsubsTi/DdIUo=";
    };
  }
)
