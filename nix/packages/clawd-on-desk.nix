{
  pname,
  pkgs,
  ...
}:

let
  inherit (pkgs)
    fetchurl
    lib
    stdenvNoCC
    undmg
    ;

  version = "0.8.1";

  sources = {
    aarch64-darwin = {
      asset = "Clawd-on-Desk-0.8.1-arm64.dmg";
      hash = "sha256-dEiXTJ/m8EPM3TOpjUgyL6nsoYvMXtJZJ6efb4VtVb8=";
    };

    x86_64-darwin = {
      asset = "Clawd-on-Desk-0.8.1-x64.dmg";
      hash = "sha256-oteVO0SAh8y3431NIgGZf9/c/ixpSDql7U9CAafUUaY=";
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
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
