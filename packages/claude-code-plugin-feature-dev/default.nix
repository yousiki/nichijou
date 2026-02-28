{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:
stdenvNoCC.mkDerivation {
  pname = "claude-code-plugin-feature-dev";
  version = "unstable-2026-02-25";

  src = fetchFromGitHub {
    owner = "anthropics";
    repo = "claude-plugins-official";
    rev = "55b58ec6e5649104f926ba7558b567dc8d33c5ff";
    hash = "sha256-pcMIh9sgdMDs0dlc0POomxnPOLoP5/EOdCGMKoESmoc=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r plugins/feature-dev/. $out/

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--flake"
      "--version"
      "branch"
    ];
  };

  meta = {
    description = "Claude Code plugin for comprehensive feature development with exploration, architecture, and review agents";
    homepage = "https://github.com/anthropics/claude-plugins-official";
    license = lib.licenses.mit;
    maintainers = [];
    platforms = lib.platforms.all;
  };
}
