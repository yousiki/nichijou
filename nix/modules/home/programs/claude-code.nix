{
  pkgs,
  lib,
  config,
  ...
}: let
  cliproxyapiApiKeyFile = config.sops.secrets."cliproxyapi-api-key".path;

  # Thin wrappers that launch the same `claude` binary but point it at the local
  # cliproxyapi (Anthropic-compatible endpoint) so it talks to non-Anthropic
  # model aliases. Everything else (settings, MCP, LSP under ~/.claude) is shared
  # with the normal `claude`.
  mkClaudeProxy = name: models: earlyCompact:
    pkgs.writeShellScriptBin name ''
      set -euo pipefail
      keyfile="${cliproxyapiApiKeyFile}"
      if [ ! -r "$keyfile" ]; then
        echo "${name}: cannot read API key file: $keyfile" >&2
        exit 1
      fi
      export ANTHROPIC_BASE_URL="http://127.0.0.1:8317"
      export ANTHROPIC_AUTH_TOKEN="$(tr -d '[:space:]' < "$keyfile")"
      export ANTHROPIC_MODEL="${models.opus}"
      export ANTHROPIC_DEFAULT_OPUS_MODEL="${models.opus}"
      export ANTHROPIC_DEFAULT_SONNET_MODEL="${models.sonnet}"
      export ANTHROPIC_DEFAULT_HAIKU_MODEL="${models.haiku}"
      export API_TIMEOUT_MS="1200000"
      export CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS="1"
      export CLAUDE_ENABLE_STREAM_WATCHDOG="1"
      export CLAUDE_STREAM_IDLE_TIMEOUT_MS="600000"
      export CLAUDE_CODE_MAX_RETRIES="3"
      export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC="1"
      ${lib.optionalString earlyCompact ''
        export CLAUDE_CODE_AUTO_COMPACT_WINDOW="220000"
        export CLAUDE_AUTOCOMPACT_PCT_OVERRIDE="60"
        export CLAUDE_CODE_MAX_OUTPUT_TOKENS="12000"
      ''}
      exec ${lib.getExe config.programs.claude-code.finalPackage} --allow-dangerously-skip-permissions "$@"
    '';

  claudeCodex =
    mkClaudeProxy "claude-codex" {
      opus = "gpt-5.5(xhigh)";
      sonnet = "gpt-5.5(medium)";
      haiku = "gpt-5.3-codex-spark";
    }
    true;

  # The `-fast` model names are forked aliases defined in
  # ~/.cliproxyapi/config.yaml whose payload override sets
  # `service_tier: "priority"` (Codex's fast lane; literal "fast" is rejected
  # upstream). Keep the old claude-codex behavior here under the explicit name.
  claudeCodexFast =
    mkClaudeProxy "claude-codex-fast" {
      opus = "gpt-5.5-fast(xhigh)";
      sonnet = "gpt-5.5-fast(medium)";
      haiku = "gpt-5.3-codex-spark";
    }
    true;

  claudeMimo =
    mkClaudeProxy "claude-mimo" {
      opus = "mimo-v2.5-pro";
      sonnet = "mimo-v2.5-pro";
      haiku = "mimo-v2.5-pro";
    }
    false;

  # Tanka's AI Work Memory spawns `claude -p ... --agent work-memory:<agent>`,
  # resolved via `which claude` against the login-shell PATH, which lands on
  # this profile's bin/claude. Shadow it (hiPrio wins the buildEnv collision)
  # with a dispatcher: work-memory subagent runs are rerouted to claude-codex
  # (cliproxyapi -> gpt-5.5) instead of the Claude subscription; every other
  # invocation passes through to the real binary unchanged.
  #
  # Note: this must NOT be set as `programs.claude-code.package`. The dispatcher
  # references finalPackage, which the module builds from `package`, so that
  # assignment is `infinite recursion` at eval time. Breaking the eval cycle by
  # referencing the raw pkgs.claude-code instead only trades it for a runtime
  # loop: finalPackage would then wrap the dispatcher, and claude-codex's
  # `exec finalPackage` would re-enter it with `--agent work-memory:*` still in
  # the args -> dispatcher -> claude-codex -> ... forever. The dispatcher has to
  # sit outside finalPackage to reference it acyclically, and the hiPrio PATH
  # shadow is exactly that: it intercepts PATH lookups (the only way Tanka finds
  # claude) while store-path references to finalPackage stay un-dispatched.
  claudeDispatch = lib.hiPrio (
    pkgs.writeShellScriptBin "claude" ''
      prev=
      for arg in "$@"; do
        if [ "$prev" = "--agent" ]; then
          case "$arg" in
            work-memory:*) exec ${lib.getExe claudeCodex} "$@" ;;
          esac
        fi
        prev=$arg
      done
      exec ${lib.getExe config.programs.claude-code.finalPackage} "$@"
    ''
  );
in {
  home.packages = [
    claudeCodex
    claudeCodexFast
    claudeMimo
    claudeDispatch
  ];

  programs.claude-code = {
    enable = true;

    # Managed declaratively -> ~/.claude/settings.json (the module adds "$schema").
    # Note: this file becomes a read-only symlink into the Nix store, so changes
    # made at runtime via `/config` will not persist; edit them here instead.
    settings = {
      theme = "auto";
      verbose = true;
      remoteControlAtStartup = true;
      inputNeededNotifEnabled = true;
      agentPushNotifEnabled = true;
      preferredNotifChannel = "auto";
      skipAutoPermissionPrompt = true;

      env = {
        CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
      };

      permissions = {
        defaultMode = "auto";
      };
    };

    # MCP servers. context7 and deepwiki use their hosted HTTP transports, so
    # they need no local runtime. nixos runs the locally-built mcp-nixos binary.
    # These are written to a generated `.mcp.json` and loaded via --plugin-dir.
    mcpServers = {
      context7 = {
        type = "http";
        url = "https://mcp.context7.com/mcp";
      };
      deepwiki = {
        type = "http";
        url = "https://mcp.deepwiki.com/mcp";
      };
      nixos = {
        type = "stdio";
        command = lib.getExe pkgs.mcp-nixos;
      };
    };

    # LSP servers. Binaries are pinned to the Nix store so they are pulled into
    # the closure and always resolvable, independent of PATH. Written to a
    # generated `.lsp.json` and loaded via --plugin-dir.
    lspServers = {
      # Python: basedpyright for completion/navigation/hover, plus Astral's ty
      # as a fast type checker. Both claim the Python extensions.
      basedpyright = {
        command = "${pkgs.basedpyright}/bin/basedpyright-langserver";
        args = ["--stdio"];
        extensionToLanguage = {
          ".py" = "python";
          ".pyi" = "python";
        };
      };
      ty = {
        command = lib.getExe pkgs.ty;
        args = ["server"];
        extensionToLanguage = {
          ".py" = "python";
          ".pyi" = "python";
        };
      };
      rust = {
        command = lib.getExe pkgs.rust-analyzer;
        args = [];
        extensionToLanguage = {
          ".rs" = "rust";
        };
      };
      nix = {
        command = lib.getExe pkgs.nixd;
        args = [];
        extensionToLanguage = {
          ".nix" = "nix";
        };
      };
      typescript = {
        command = lib.getExe pkgs.typescript-language-server;
        args = [
          "--stdio"
          "--tsserver-path"
          "${pkgs.typescript}/lib/node_modules/typescript/lib"
        ];
        extensionToLanguage = {
          ".ts" = "typescript";
          ".mts" = "typescript";
          ".cts" = "typescript";
          ".tsx" = "typescriptreact";
          ".js" = "javascript";
          ".mjs" = "javascript";
          ".cjs" = "javascript";
          ".jsx" = "javascriptreact";
        };
      };
    };
  };
}
