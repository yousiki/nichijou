{
  fetchurl,
  pkgs,
}:
pkgs.rectangle.overrideAttrs (
  finalAttrs: _prevAttrs: {
    version = "0.89";

    src = fetchurl {
      url = "https://github.com/rxhanson/Rectangle/releases/download/v${finalAttrs.version}/Rectangle${finalAttrs.version}.dmg";
      hash = "sha256-eI3C+nDJhxKwbCLRKepoGmbyWKGCxEuMSK3D0sZbDU0=";
    };
  }
)
