{
  pname,
  pkgs,
  ...
}:

let
  inherit (pkgs) fetchurl lib stdenvNoCC;

  version = "7.1.32";

  sources = {
    aarch64-darwin = {
      asset = "CLIProxyAPI_7.1.32_darwin_aarch64.tar.gz";
      hash = "sha256-hmM2nJQBZ8Yedwe1Yc9s+JSLEVfXRNF1JjEzXjOD8Rw=";
    };

    x86_64-darwin = {
      asset = "CLIProxyAPI_7.1.32_darwin_amd64.tar.gz";
      hash = "sha256-76C24dqISbA3iFXPZDauG8sClRgQIcbz8VdT9xINBr4=";
    };

    x86_64-linux = {
      asset = "CLIProxyAPI_7.1.32_linux_amd64.tar.gz";
      hash = "sha256-asIb0CCI9VO22eNRyBnFBJhXYnm4GBksm5WEn4RoiE8=";
    };

    aarch64-linux = {
      asset = "CLIProxyAPI_7.1.32_linux_aarch64.tar.gz";
      hash = "sha256-81gwS5opd589j4Qp01sA/CSjfXCDz26ZLSm6VesiXMQ=";
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
