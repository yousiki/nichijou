{
  pname,
  pkgs,
  ...
}:

let
  inherit (pkgs) fetchurl lib stdenvNoCC;

  version = "7.1.56";

  sources = {
    aarch64-darwin = {
      asset = "CLIProxyAPI_7.1.56_darwin_aarch64.tar.gz";
      hash = "sha256-81s6MI/0aOt+AYWdPrGiNLx6hS4ApHMprKK2UvIEaco=";
    };

    x86_64-darwin = {
      asset = "CLIProxyAPI_7.1.56_darwin_amd64.tar.gz";
      hash = "sha256-ujhOZ+b60/7DVOttpebFJPUBcgyCXsfizXBi2wpeGMI=";
    };

    x86_64-linux = {
      asset = "CLIProxyAPI_7.1.56_linux_amd64.tar.gz";
      hash = "sha256-yxm3g3T4c389RCrwXQPpCysOkYmnDciWxfcvGPiFEd8=";
    };

    aarch64-linux = {
      asset = "CLIProxyAPI_7.1.56_linux_aarch64.tar.gz";
      hash = "sha256-fIzMbDQl9Mm4oRQkYERLRSw1usL202b3hQaMRknNLHs=";
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
