{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:
stdenvNoCC.mkDerivation {
  pname = "claude-code-plugin-context7";
  version = "unstable-2026-03-06";

  src = fetchFromGitHub {
    owner = "upstash";
    repo = "context7";
    rev = "c796a74ee421b80122a3aefda7e016576652509f";
    hash = "sha256-vT26oWQI+J7s/0YBEQw9Db2eSNKTJ2i8ojntFzYyuvQ=";
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
