{
  pname,
  pkgs,
  ...
}:

let
  inherit (pkgs) fetchurl lib stdenvNoCC;

  version = "7.1.25";

  sources = {
    aarch64-darwin = {
      asset = "CLIProxyAPI_7.1.25_darwin_aarch64.tar.gz";
      hash = "sha256-lTUPxq+vDkiG0cDiUfMd2mXqyJDLZkdBY34mG8kFuGM=";
    };

    x86_64-darwin = {
      asset = "CLIProxyAPI_7.1.25_darwin_amd64.tar.gz";
      hash = "sha256-yvg6LkL73V6tin2QZXZEiv98dosFchADxjiL3J+02cc=";
    };

    x86_64-linux = {
      asset = "CLIProxyAPI_7.1.25_linux_amd64.tar.gz";
      hash = "sha256-yZk8oaaHYp71rZ88W29SfSlGZgOxqorsQu+ulerRXoI=";
    };

    aarch64-linux = {
      asset = "CLIProxyAPI_7.1.25_linux_aarch64.tar.gz";
      hash = "sha256-BJllCdOTzhKi1RWJNDPxpOoImPwu+zyTLHGE8hleH8g=";
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
