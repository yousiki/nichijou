{
  pname,
  pkgs,
  ...
}:

let
  inherit (pkgs) fetchurl lib stdenvNoCC;

  version = "0.18.0";

  sources = {
    aarch64-darwin = {
      asset = "jcode-macos-aarch64";
      hash = "sha256-ZXpJzDSlbD7sT0CrjHWt0shIQNaC6UAHjDTlF7ZFi9k=";
    };

    x86_64-darwin = {
      asset = "jcode-macos-x86_64";
      hash = "sha256-Cx0nSAA6fAv4dGdl1XuQt7QMM6MtkdtR7LkR2ltNlXQ=";
    };

    x86_64-linux = {
      asset = "jcode-linux-x86_64";
      hash = "sha256-LQElA7fkBFtFMgVZ6HSKeRgWOXTUilMie+ijRwTnMOg=";
    };

    aarch64-linux = {
      asset = "jcode-linux-aarch64";
      hash = "sha256-XGEB+Qe6LtSVOw5pbS6mff1pMJ4I7ie6tIYZoM7R+N0=";
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
