{
  pname,
  pkgs,
  ...
}:

let
  inherit (pkgs) fetchurl lib stdenvNoCC;

  version = "7.1.44";

  sources = {
    aarch64-darwin = {
      asset = "CLIProxyAPI_7.1.44_darwin_aarch64.tar.gz";
      hash = "sha256-48zBQV5lVE7wd6t5pzqFtL9tpVNfmFa62MhzA8/WMS8=";
    };

    x86_64-darwin = {
      asset = "CLIProxyAPI_7.1.44_darwin_amd64.tar.gz";
      hash = "sha256-KD97hXXs5QbHLIm3P0TF7PW5QbTjT2a1kqG5YkesYjA=";
    };

    x86_64-linux = {
      asset = "CLIProxyAPI_7.1.44_linux_amd64.tar.gz";
      hash = "sha256-XVHgkO1s62lboW/o2c23y2PYfOryEuLD6Hw8BqShuNI=";
    };

    aarch64-linux = {
      asset = "CLIProxyAPI_7.1.44_linux_aarch64.tar.gz";
      hash = "sha256-rvnSwuWbgKDVzks+13c4DvWHZkcC4ceDCR4rpECJzWA=";
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
