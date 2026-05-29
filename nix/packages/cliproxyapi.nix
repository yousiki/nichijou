{
  pname,
  pkgs,
  ...
}:

let
  inherit (pkgs) fetchurl lib stdenvNoCC;

  version = "7.1.29";

  sources = {
    aarch64-darwin = {
      asset = "CLIProxyAPI_7.1.29_darwin_aarch64.tar.gz";
      hash = "sha256-9x+kjU21uB3XrPIbBaP3OhsTJjm8z3rpFyRUfHgtWqU=";
    };

    x86_64-darwin = {
      asset = "CLIProxyAPI_7.1.29_darwin_amd64.tar.gz";
      hash = "sha256-jK1M/nUQzy1GdIz6hqD2Kci/ev6spdatNWJw171H1ck=";
    };

    x86_64-linux = {
      asset = "CLIProxyAPI_7.1.29_linux_amd64.tar.gz";
      hash = "sha256-2h/MIX1NeBwFssMgLPdUGX+DDY50Qm5IgEtBDFm6q08=";
    };

    aarch64-linux = {
      asset = "CLIProxyAPI_7.1.29_linux_aarch64.tar.gz";
      hash = "sha256-n7HcGUnhXtUvIJNUVJ1LFIgx7zQyx3h0ocXSf0vBgu0=";
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
