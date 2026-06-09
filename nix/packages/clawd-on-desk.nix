{
  pname,
  pkgs,
  ...
}: let
  inherit
    (pkgs)
    fetchurl
    lib
    stdenvNoCC
    undmg
    ;

  version = "0.9.0";

  sources = {
    aarch64-darwin = {
      asset = "Clawd-on-Desk-0.9.0-arm64.dmg";
      hash = "sha256-7v8ULAF8w3avGXDUh3BMqQrpKwRQyEC4HzYRqvb68fs=";
    };

    x86_64-darwin = {
      asset = "Clawd-on-Desk-0.9.0-x64.dmg";
      hash = "sha256-eewQ4peytxiW1XeYHBIDVCIGH1nBnjWMUop5l1lQC1U=";
    };
  };

  source =
    sources.${stdenvNoCC.hostPlatform.system}
      or (throw "clawd-on-desk is not packaged for ${stdenvNoCC.hostPlatform.system}");
in
  stdenvNoCC.mkDerivation {
    inherit pname version;

    src = fetchurl {
      url = "https://github.com/rullerzhou-afk/clawd-on-desk/releases/download/v${version}/${source.asset}";
      inherit (source) hash;
    };

    sourceRoot = ".";

    nativeBuildInputs = [
      undmg
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/Applications"
      cp -R "Clawd on Desk.app" "$out/Applications/"

      runHook postInstall
    '';

    dontFixup = true;

    meta = {
      description = "Desktop pet that reacts to AI coding agent sessions";
      homepage = "https://github.com/rullerzhou-afk/clawd-on-desk";
      license = lib.licenses.agpl3Only;
      platforms = builtins.attrNames sources;
      sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
    };
  }
