{
  pname,
  pkgs,
  ...
}: let
  inherit (pkgs) fetchurl lib stdenvNoCC;

  version = "0.25.0";

  sources = {
    aarch64-darwin = {
      asset = "jcode-macos-aarch64";
      hash = "sha256-483SMaJdLcZjAR4DyBVgTpjSyLCvXGyt72d6N63vGL0=";
    };

    x86_64-darwin = {
      asset = "jcode-macos-x86_64";
      hash = "sha256-pBcBeVsMXxTvft5Wd+W+mPWrmJep8uy318bvx9J8dTE=";
    };

    x86_64-linux = {
      asset = "jcode-linux-x86_64";
      hash = "sha256-5I8XXkn67XXmFNfRTOI6EL2S1L/1gJniqusFGa2sB48=";
    };

    aarch64-linux = {
      asset = "jcode-linux-aarch64";
      hash = "sha256-Vf4dgblE5LymcYFA5W+pGyd9G+BCUwOZsERkeedlEzY=";
    };
  };

  source =
    sources.${stdenvNoCC.hostPlatform.system}
      or (throw "jcode is not packaged for ${stdenvNoCC.hostPlatform.system}");
in
  stdenvNoCC.mkDerivation {
    inherit pname version;

    src = fetchurl {
      url = "https://github.com/1jehuang/jcode/releases/download/v${version}/${source.asset}.tar.gz";
      inherit (source) hash;
    };

    sourceRoot = ".";

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/bin"

      if [ -f "${source.asset}.bin" ]; then
        mkdir -p "$out/libexec/jcode"
        install -m755 "${source.asset}" "$out/libexec/jcode/${source.asset}"
        install -m755 "${source.asset}.bin" "$out/libexec/jcode/${source.asset}.bin"

        for library in libssl.so* libcrypto.so*; do
          if [ -e "$library" ]; then
            install -m644 "$library" "$out/libexec/jcode/$library"
          fi
        done

        ln -s "$out/libexec/jcode/${source.asset}" "$out/bin/jcode"
      else
        install -m755 "${source.asset}" "$out/bin/jcode"
      fi

      runHook postInstall
    '';

    meta = {
      description = "Coding agent harness for multi-session workflows";
      homepage = "https://github.com/1jehuang/jcode";
      license = lib.licenses.mit;
      mainProgram = "jcode";
      platforms = builtins.attrNames sources;
    };
  }
