{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "keepingyouawake";
  version = "1.6.6";

  src = fetchurl {
    name = "KeepingYouAwake-${finalAttrs.version}.zip";
    url = "https://github.com/newmarcel/KeepingYouAwake/releases/download/${finalAttrs.version}/KeepingYouAwake-${finalAttrs.version}.zip";
    hash = "sha256-5f63jlIIDORtrMyA1aZcfXrNWLEGsSEuI1JMdfPYlDo=";
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
    maintainers = with lib.maintainers; [
    ];
    platforms = [
      "aarch64-darwin"
      "x86_64-darwin"
    ];
  };
})
