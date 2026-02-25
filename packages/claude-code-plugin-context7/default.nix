{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:
stdenvNoCC.mkDerivation {
  pname = "claude-code-plugin-context7";
  version = "unstable-2026-02-23";

  src = fetchFromGitHub {
    owner = "upstash";
    repo = "context7";
    rev = "76d70a12230bf23f5ffb3f35288ec6c25fa41874";
    hash = "sha256-6P1G2NsR/PKwQlp/VfyH0QbXa4Fs/WHIA50DZWTnbP4=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r plugins/claude/context7/. $out/
    cp -r plugins/claude/context7/.claude-plugin $out/
    cp plugins/claude/context7/.mcp.json $out/

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
    description = "Claude Code plugin for Context7 — up-to-date documentation lookup via MCP";
    homepage = "https://github.com/upstash/context7";
    license = lib.licenses.mit;
    maintainers = [];
    platforms = lib.platforms.all;
  };
}
