{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:
stdenvNoCC.mkDerivation {
  pname = "claude-code-plugin-hookify";
  version = "unstable-2026-03-04";

  src = fetchFromGitHub {
    owner = "anthropics";
    repo = "claude-plugins-official";
    rev = "205b6e0b30366a969412d9aab7b99bea99d58db1";
    hash = "sha256-0iZO5ZS0BO0LKkCDxwk+H07w/re7+w84X17h3GH23eM=";
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
