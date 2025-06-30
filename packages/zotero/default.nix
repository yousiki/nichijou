{
  pkgs,
  fetchurl,
  ...
}:
pkgs.zotero.overrideAttrs (
  finalAttrs: _prevAttrs: {
    version = if pkgs.stdenv.hostPlatform.isDarwin then "7.0.18" else "7.0.19";

    src =
      if pkgs.stdenv.hostPlatform.isDarwin then
        fetchurl {
          url = "https://download.zotero.org/client/release/${finalAttrs.version}/Zotero-${finalAttrs.version}.dmg";
          hash = "sha256-Eu1DOq6cyUvgDmdAZOPWR/xVPWjnPsN8u6OyYhue/5o=";
        }
      else
        fetchurl {
          url = "https://download.zotero.org/client/release/${finalAttrs.version}/Zotero-${finalAttrs.version}_linux-x86_64.tar.bz2";
          hash = "sha256-bl6ZEzPEqoK7MFjc884bDVr4MrQ2jVgklJ1wkvrIBTA=";
        };
  }
)
