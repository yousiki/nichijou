{
  pname,
  pkgs,
  ...
}:

let
  inherit (pkgs) fetchurl lib stdenvNoCC;

  version = "0.14.3";

  sources = {
    aarch64-darwin = {
      asset = "jcode-macos-aarch64";
      hash = "sha256-7+NSKBZM6Fi14xhosvaqu32QZH3wlAyWJSGxPopxfXQ=";
    };

    x86_64-darwin = {
      asset = "jcode-macos-x86_64";
      hash = "sha256-2lC5KLqkVfq9zggsgO9uhPgU9r7JyMA+wMmfkr+gG2M=";
    };

    x86_64-linux = {
      asset = "jcode-linux-x86_64";
      hash = "sha256-Mp61GnTBuUuV8vEJlZpFkMaKlbeFkRdB4h8q78+jCQU=";
    };

    aarch64-linux = {
      asset = "jcode-linux-aarch64";
      hash = "sha256-x9RddW0mBhbl5ZgyBW4ycTgOlumP2sR62gta5a70HdY=";
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
