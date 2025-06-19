{
  fetchurl,
  lib,
  stdenvNoCC,
  unzip,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "ice";
  version = "0.11.12";

  src = fetchurl {
    name = "Ice-${finalAttrs.version}.zip";
    url = "https://github.com/jordanbaird/Ice/releases/download/${finalAttrs.version}/Ice.zip";
    hash = "sha256-13DoFZdWbdLSNj/rNQ+AjHqS42PflcUeSBQOsw5FLMk=";
  };

  dontPatch = true;
  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  nativeBuildInputs = [ unzip ];

  sourceRoot = "Ice.app";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/Applications/Ice.app
    cp -R . $out/Applications/Ice.app

    runHook postInstall
  '';

  meta = {
    description = "Powerful menu bar manager for macOS.";
    homepage = "https://icemenubar.app/";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.darwin;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
