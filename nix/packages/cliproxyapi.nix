{
  pname,
  pkgs,
  ...
}:

let
  inherit (pkgs) fetchurl lib stdenvNoCC;

  version = "7.1.39";

  sources = {
    aarch64-darwin = {
      asset = "CLIProxyAPI_7.1.39_darwin_aarch64.tar.gz";
      hash = "sha256-PdSKbRnRHmWl0CW0yY5ro5fXnqbUw2Pk+3l5DEL+8tk=";
    };

    x86_64-darwin = {
      asset = "CLIProxyAPI_7.1.39_darwin_amd64.tar.gz";
      hash = "sha256-wSWKz5jy5qFZvoBNzcZe8Ex+/X7ew/jBWxleNjzN6EM=";
    };

    x86_64-linux = {
      asset = "CLIProxyAPI_7.1.39_linux_amd64.tar.gz";
      hash = "sha256-DSA4KLPh3oX3qSqK9oOuqEIWDtV7y80r2l8U0Ww3+6o=";
    };

    aarch64-linux = {
      asset = "CLIProxyAPI_7.1.39_linux_aarch64.tar.gz";
      hash = "sha256-1z74uvTm4TcqJTwRDO3KZ/yeXLd11gJEakYoDW+YWJ8=";
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
