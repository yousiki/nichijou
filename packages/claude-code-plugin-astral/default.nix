{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:
stdenvNoCC.mkDerivation {
  pname = "claude-code-plugin-astral";
  version = "unstable-2026-01-09";

  src = fetchFromGitHub {
    owner = "astral-sh";
    repo = "claude-code-plugins";
    rev = "f8034678a15ad751aae6a2b684daebac416267a1";
    hash = "sha256-huyQOHqWFNIT0xsBdp4ZwApOa/mVX2eX1CA4/JDd1d4=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r plugins/astral/. $out/

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
    description = "Claude Code plugin for Python development with Astral tools (ruff, ty, uv)";
    homepage = "https://github.com/astral-sh/claude-code-plugins";
    license = lib.licenses.mit;
    maintainers = [];
    platforms = lib.platforms.all;
  };
}
