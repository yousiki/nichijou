{
  fetchurl,
  lib,
  stdenvNoCC,
  unzip,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "keepingyouawake";
  version = "1.6.7";

  src = fetchurl {
    name = "KeepingYouAwake-${finalAttrs.version}.zip";
    url = "https://github.com/newmarcel/KeepingYouAwake/releases/download/${finalAttrs.version}/KeepingYouAwake-${finalAttrs.version}.zip";
    hash = "sha256-/Y2y7FNvP7AmB7vBe+Goaxc6n3IzE1HrB2pjMpzF2RU=";
  };

  dontPatch = true;
  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  nativeBuildInputs = [ unzip ];

  sourceRoot = "KeepingYouAwake.app";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/Applications/KeepingYouAwake.app
    cp -R . $out/Applications/KeepingYouAwake.app

    runHook postInstall
  '';

  meta = {
    description = "Prevents your Mac from going to sleep.";
    homepage = "https://keepingyouawake.app/";
    license = lib.licenses.mit;
    platforms = lib.platforms.darwin;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
