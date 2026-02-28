{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:
stdenvNoCC.mkDerivation {
  pname = "claude-code-plugin-ralph-loop";
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
    cp -r plugins/ralph-loop/. $out/

    runHook postInstall
  '';

  postFixup = ''
    # Fix shebangs in hook and script files
    find $out/hooks $out/scripts -type f \( -name '*.sh' -o -executable \) 2>/dev/null | while read f; do
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
    description = "Claude Code plugin for continuous iterative development loops";
    homepage = "https://github.com/anthropics/claude-plugins-official";
    license = lib.licenses.mit;
    maintainers = [];
    platforms = lib.platforms.all;
  };
}
