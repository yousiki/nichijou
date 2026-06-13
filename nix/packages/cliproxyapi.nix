{
  pname,
  pkgs,
  ...
}: let
  inherit (pkgs) fetchurl lib stdenvNoCC;

  version = "7.1.75";

  sources = {
    aarch64-darwin = {
      asset = "CLIProxyAPI_7.1.75_darwin_aarch64.tar.gz";
      hash = "sha256-NXiqIHcSoWv44i8OyE+gt3hDoap6nWZKr8xYBoEtIEA=";
    };

    x86_64-darwin = {
      asset = "CLIProxyAPI_7.1.75_darwin_amd64.tar.gz";
      hash = "sha256-VQ7z1meJICVPQCtCSYP9Cyho17E9foR+DZFbhaFKWc4=";
    };

    x86_64-linux = {
      asset = "CLIProxyAPI_7.1.75_linux_amd64.tar.gz";
      hash = "sha256-RusrQ/rgAYWT9eAJ21ozLCNMYuXEbJ7wGIH+Hx52a0w=";
    };

    aarch64-linux = {
      asset = "CLIProxyAPI_7.1.75_linux_aarch64.tar.gz";
      hash = "sha256-hT9Hs8TFoJ/Xi6AHUrcglOoTwGwOg3jhM2KyO9tgiGg=";
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
