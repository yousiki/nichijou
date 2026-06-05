{
  pname,
  pkgs,
  ...
}:

let
  inherit (pkgs) fetchurl lib stdenvNoCC;

  version = "7.1.45";

  sources = {
    aarch64-darwin = {
      asset = "CLIProxyAPI_7.1.45_darwin_aarch64.tar.gz";
      hash = "sha256-oW+Qd8Gk4TgI9+wZCfShaIph+HEZKD+utMwp4NK7s0A=";
    };

    x86_64-darwin = {
      asset = "CLIProxyAPI_7.1.45_darwin_amd64.tar.gz";
      hash = "sha256-iOnFgaASvLSrZ7bQPfsNl3F74r3v/bkadX1Ma2/nAwo=";
    };

    x86_64-linux = {
      asset = "CLIProxyAPI_7.1.45_linux_amd64.tar.gz";
      hash = "sha256-bQVsFqp5WirsyEM94dbkzIraKoxxqTEQDyne8bgeKpU=";
    };

    aarch64-linux = {
      asset = "CLIProxyAPI_7.1.45_linux_aarch64.tar.gz";
      hash = "sha256-LVnNTBfu/Ju551Y9SiGaiL/ww2DEuO0e8Do9Xi4og2o=";
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
