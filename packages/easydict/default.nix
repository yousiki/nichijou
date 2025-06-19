{
  fetchurl,
  lib,
  stdenvNoCC,
  unzip,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "easydict";
  version = "2.14.1";

  src = fetchurl {
    name = "easydict-${finalAttrs.version}.zip";
    url = "https://github.com/tisfeng/Easydict/releases/download/${finalAttrs.version}/Easydict.zip";
    hash = "sha256-SvhULDUQ/G7TzKTvasexKnUo3ttZFM/19jplfghbziQ=";
  };

  dontPatch = true;
  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  nativeBuildInputs = [ unzip ];

  sourceRoot = "Easydict.app";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/Applications/Easydict.app
    cp -R . $out/Applications/Easydict.app

    runHook postInstall
  '';

  meta = {
    description = "A concise and elegant Dictionary and Translator macOS App for looking up words and translating text.";
    homepage = "https://www.easydict.app/";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.darwin;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
