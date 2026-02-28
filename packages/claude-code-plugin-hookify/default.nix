{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:
stdenvNoCC.mkDerivation {
  pname = "claude-code-plugin-hookify";
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
    cp -r plugins/hookify/. $out/

    runHook postInstall
  '';

  postFixup = ''
    # Fix shebangs in Python hook scripts
    find $out/hooks -type f -name '*.py' 2>/dev/null | while read f; do
      patchShebangs "$f"
    done
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--flake"
      "--version"
      "branch"
    ];
  };

  meta = {
    description = "Claude Code plugin for creating custom hooks from instructions or conversation analysis";
    homepage = "https://github.com/anthropics/claude-plugins-official";
    license = lib.licenses.mit;
    maintainers = [];
    platforms = lib.platforms.all;
  };
}
