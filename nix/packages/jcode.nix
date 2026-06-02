{
  pname,
  pkgs,
  ...
}:

let
  inherit (pkgs) fetchurl lib stdenvNoCC;

  version = "0.18.4";

  sources = {
    aarch64-darwin = {
      asset = "jcode-macos-aarch64";
      hash = "sha256-v6pTPNhfUN1CHAGJlYtBHOsYeSlKnU3EfZyynTDmzQs=";
    };

    x86_64-darwin = {
      asset = "jcode-macos-x86_64";
      hash = "sha256-W5xnDsSSgR3NuSfh/4Rn7DUrNeaKT/iasw05fR7MQzc=";
    };

    x86_64-linux = {
      asset = "jcode-linux-x86_64";
      hash = "sha256-0ANYNSqS5Ey4wiONKFJs6UBNdDjkfxBeVr134Eol27o=";
    };

    aarch64-linux = {
      asset = "jcode-linux-aarch64";
      hash = "sha256-HsDmlD99D7wrjgt2kHBhS6Mkkq6q1stGkF5tdM+e8BE=";
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
