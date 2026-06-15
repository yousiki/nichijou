{
  pname,
  pkgs,
  ...
}: let
  inherit (pkgs) fetchurl lib stdenvNoCC;

  version = "7.2.3";

  sources = {
    aarch64-darwin = {
      asset = "CLIProxyAPI_7.2.3_darwin_aarch64.tar.gz";
      hash = "sha256-z5F6EXYtSFXHY/mNn9GjTzubrGoZ0m8h0mZehQ7uDG4=";
    };

    x86_64-darwin = {
      asset = "CLIProxyAPI_7.2.3_darwin_amd64.tar.gz";
      hash = "sha256-MjqDymnYIW3qNX6sMOdnhGX45uchTBe9Sb/xOb5D0Zg=";
    };

    x86_64-linux = {
      asset = "CLIProxyAPI_7.2.3_linux_amd64.tar.gz";
      hash = "sha256-ncRhdoSm71G0oo1yAiDVR0WcSlL0aU4/KJ8CDAUEcmc=";
    };

    aarch64-linux = {
      asset = "CLIProxyAPI_7.2.3_linux_aarch64.tar.gz";
      hash = "sha256-9rY5/ok4HCn0NRCbpv2OgIWfqQRF1mbvE/LwR4qFekk=";
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
