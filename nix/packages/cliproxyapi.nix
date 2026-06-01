{
  pname,
  pkgs,
  ...
}:

let
  inherit (pkgs) fetchurl lib stdenvNoCC;

  version = "7.1.36";

  sources = {
    aarch64-darwin = {
      asset = "CLIProxyAPI_7.1.36_darwin_aarch64.tar.gz";
      hash = "sha256-g7kXQuu/GzSZPr2mXnLL3/PossOw67R52oJidrrtsEM=";
    };

    x86_64-darwin = {
      asset = "CLIProxyAPI_7.1.36_darwin_amd64.tar.gz";
      hash = "sha256-+N4ddnbPMIon5dmAXBqjxpNia+Yw/ImohXmrAAMXfo8=";
    };

    x86_64-linux = {
      asset = "CLIProxyAPI_7.1.36_linux_amd64.tar.gz";
      hash = "sha256-aEUzwpMQ0lpwh3Gs3VTwyHncUHWf16eKb/1cVWNW3z4=";
    };

    aarch64-linux = {
      asset = "CLIProxyAPI_7.1.36_linux_aarch64.tar.gz";
      hash = "sha256-NzQaP39qx7hs6cPyZ+5Wpxf4V/RbFRcP5qrx0+9QBUQ=";
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
