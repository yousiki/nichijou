{
  pname,
  pkgs,
  ...
}: let
  inherit (pkgs) fetchurl lib stdenvNoCC;

  version = "7.1.60";

  sources = {
    aarch64-darwin = {
      asset = "CLIProxyAPI_7.1.60_darwin_aarch64.tar.gz";
      hash = "sha256-7neeZ3G3KnLK1ul//gxOhYMlhb9oBQ6kJ1dECYBiWKw=";
    };

    x86_64-darwin = {
      asset = "CLIProxyAPI_7.1.60_darwin_amd64.tar.gz";
      hash = "sha256-fchPtRkPMd1PLJFH+CrOlwkiw3/E4qFJ/gpjWGR3bns=";
    };

    x86_64-linux = {
      asset = "CLIProxyAPI_7.1.60_linux_amd64.tar.gz";
      hash = "sha256-EvCs6yLxF6QVbb6+sBRax0j5b46LO7NC3jQQXBnFZiU=";
    };

    aarch64-linux = {
      asset = "CLIProxyAPI_7.1.60_linux_aarch64.tar.gz";
      hash = "sha256-Kzafd1sCTIJucd27DvcfKSPpBqnVMrzpiAT0taomkuM=";
    };
  };

  source =
    sources.${stdenvNoCC.hostPlatform.system}
      or (throw "cliproxyapi is not packaged for ${stdenvNoCC.hostPlatform.system}");
in
  stdenvNoCC.mkDerivation {
    inherit pname version;

    src = fetchurl {
      url = "https://github.com/router-for-me/CLIProxyAPI/releases/download/v${version}/${source.asset}";
      inherit (source) hash;
    };

    sourceRoot = ".";

    installPhase = ''
      runHook preInstall

      install -D -m755 cli-proxy-api "$out/bin/cli-proxy-api"
      ln -s "$out/bin/cli-proxy-api" "$out/bin/cliproxyapi"

      runHook postInstall
    '';

    meta = {
      description = "OpenAI/Gemini/Claude/Codex compatible API service for CLI coding tools";
      homepage = "https://github.com/router-for-me/CLIProxyAPI";
      license = lib.licenses.mit;
      mainProgram = "cliproxyapi";
      platforms = builtins.attrNames sources;
    };
  }
