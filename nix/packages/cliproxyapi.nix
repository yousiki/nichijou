{
  pname,
  pkgs,
  ...
}:

let
  inherit (pkgs) fetchurl lib stdenvNoCC;

  version = "7.1.37";

  sources = {
    aarch64-darwin = {
      asset = "CLIProxyAPI_7.1.37_darwin_aarch64.tar.gz";
      hash = "sha256-58A4ZiKAEcg+6qN7ffn5o0EuisoilikncKfKs0PiII4=";
    };

    x86_64-darwin = {
      asset = "CLIProxyAPI_7.1.37_darwin_amd64.tar.gz";
      hash = "sha256-7AGBQpHO2L0HD8stn8Xi49CSdyrgge+hXMuuFUV8m3E=";
    };

    x86_64-linux = {
      asset = "CLIProxyAPI_7.1.37_linux_amd64.tar.gz";
      hash = "sha256-ihWF0agQyA1AaCNrlWhcVf9yuxvd5W7iRPRgjUHwb0s=";
    };

    aarch64-linux = {
      asset = "CLIProxyAPI_7.1.37_linux_aarch64.tar.gz";
      hash = "sha256-BpinFbfVwT/1mcmlBc0KG6kHnNEv/0hGKF2OERAB0Gc=";
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
