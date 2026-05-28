{
  pname,
  pkgs,
  ...
}:

let
  inherit (pkgs) fetchurl lib stdenvNoCC;

  version = "7.1.24";

  sources = {
    aarch64-darwin = {
      asset = "CLIProxyAPI_7.1.24_darwin_aarch64.tar.gz";
      hash = "sha256-iqydNqPCniQ7jicb/RPMYPJnohv1G+yZIdjo0OHx2Gs=";
    };

    x86_64-darwin = {
      asset = "CLIProxyAPI_7.1.24_darwin_amd64.tar.gz";
      hash = "sha256-W12WbL5GX9dTTx6mljtgSCQeSEkpvaj6ZpRZ1JwiZfo=";
    };

    x86_64-linux = {
      asset = "CLIProxyAPI_7.1.24_linux_amd64.tar.gz";
      hash = "sha256-ih5BKXqXEsCRbMAvhJxdukayaFvHoZuWzWJ8JoTznZ4=";
    };

    aarch64-linux = {
      asset = "CLIProxyAPI_7.1.24_linux_aarch64.tar.gz";
      hash = "sha256-fOMu4tdDFFszPoBxJ1MjuQ3GMIzWak8rRFk8sJ+4sTw=";
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
