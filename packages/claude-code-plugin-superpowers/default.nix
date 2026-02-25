{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:
stdenvNoCC.mkDerivation rec {
  pname = "claude-code-plugin-superpowers";
  version = "4.3.1";

  src = fetchFromGitHub {
    owner = "obra";
    repo = "superpowers";
    rev = "v${version}";
    hash = "sha256-/3T9haaI5x7wVLAy+z8NzaH5hI1qvIa2nTKq91jNNXA=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r .claude-plugin skills agents commands hooks lib $out/
    # Copy top-level files needed by the plugin runtime
    for f in LICENSE README.md; do
      [ -f "$f" ] && cp "$f" $out/
    done

    runHook postInstall
  '';

  postFixup = ''
    # Fix shebangs in hook scripts
    find $out/hooks -type f -executable 2>/dev/null | while read f; do
      patchShebangs "$f"
    done
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--flake"
      "--version-regex"
      "v(.*)"
    ];
  };

  meta = {
    description = "Core skills library for Claude Code — TDD, debugging, planning, and more";
    homepage = "https://github.com/obra/superpowers";
    license = lib.licenses.mit;
    maintainers = [];
    platforms = lib.platforms.all;
  };
}
