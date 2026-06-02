{
  pkgs,
  lib,
  config,
  inputs,
  perSystem,
  ...
}:

let
  # Thin wrappers that launch the same `claude` binary but point it at the local
  # cliproxyapi (Anthropic-compatible endpoint) so it talks to non-Anthropic
  # model aliases. Everything else (settings, MCP, LSP under ~/.claude) is shared
  # with the normal `claude`.
  mkClaudeProxy =
    name: models: earlyCompact:
    pkgs.writeShellScriptBin name ''
      set -euo pipefail
      keyfile="${config.home.homeDirectory}/.cliproxyapi/api-key.txt"
      if [ ! -r "$keyfile" ]; then
        echo "${name}: cannot read API key file: $keyfile" >&2
        exit 1
      fi
      export ANTHROPIC_BASE_URL="http://127.0.0.1:8317"
      export ANTHROPIC_AUTH_TOKEN="$(tr -d '[:space:]' < "$keyfile")"
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
        export CLAUDE_CODE_AUTO_COMPACT_WINDOW="350000"
        export CLAUDE_AUTOCOMPACT_PCT_OVERRIDE="85"
        export CLAUDE_CODE_MAX_OUTPUT_TOKENS="16384"
      ''}
      exec ${lib.getExe config.programs.claude-code.finalPackage} "$@"
    '';

  claudeCodex = mkClaudeProxy "claude-codex" {
    opus = "gpt-5.5(xhigh)";
    sonnet = "gpt-5.5(medium)";
    haiku = "gpt-5.4-mini";
  } true;

  # The `-fast` model names are forked aliases defined in
  # ~/.cliproxyapi/config.yaml whose payload override sets
  # `service_tier: "priority"` (Codex's fast lane; literal "fast" is rejected
  # upstream). Keep the old claude-codex behavior here under the explicit name.
  claudeCodexFast = mkClaudeProxy "claude-codex-fast" {
    opus = "gpt-5.5-fast(xhigh)";
    sonnet = "gpt-5.5-fast(medium)";
    haiku = "gpt-5.4-mini-fast";
  } true;

  claudeMimo = mkClaudeProxy "claude-mimo" {
    opus = "mimo-v2.5-pro";
    sonnet = "mimo-v2.5-pro";
    haiku = "mimo-v2.5-pro";
  } false;

  # ---------------------------------------------------------------------------
  # Clawd on Desk integration
  #
  # "Clawd on Desk" is a desktop pet that reacts to Claude Code sessions. The
  # app normally injects its own hooks into ~/.claude/settings.json at runtime;
  # we manage them declaratively here instead (its auto-install is disabled).
  #
  # First gate (home-manager eval time): only wire the hooks in when we are on
  # macOS *and* the clawd-on-desk package is actually part of this profile.
  # Hosts that never install the app get a clean settings.json with no hooks.
  clawdInstalled = lib.any (p: lib.getName p == "clawd-on-desk") config.home.packages;
  clawdEnabled = pkgs.stdenv.hostPlatform.isDarwin && clawdInstalled;

  # Reference the app straight out of the Nix store so the path always tracks
  # the exact installed version. Only evaluated when clawdEnabled is true, so
  # this never pulls clawd-on-desk into a closure that does not already have it.
  clawdHookScript =
    "${perSystem.self.clawd-on-desk}/Applications/Clawd on Desk.app"
    + "/Contents/Resources/app.asar.unpacked/hooks/clawd-hook.js";

  # Second gate (runtime): a tiny wrapper that runs the hook with Bun, but only
  # if both the Bun runtime and the hook script truly exist on disk. If the app
  # was removed out-of-band the wrapper exits 0 silently and never breaks the
  # calling Claude Code session.
  clawdHookRunner = pkgs.writeShellScript "clawd-hook-runner" ''
    set -u
    event="''${1:-}"
    bun="${lib.getExe pkgs.bun}"
    hook="${clawdHookScript}"
    if [ -n "$event" ] && [ -x "$bun" ] && [ -f "$hook" ]; then
      exec "$bun" "$hook" "$event"
    fi
    exit 0
  '';

  # Lifecycle events Clawd on Desk listens to, each fired as an async command
  # hook with a short timeout (mirrors the app's own injected configuration).
  clawdCommandEvents = [
    "SessionStart"
    "SessionEnd"
    "UserPromptSubmit"
    "PreToolUse"
    "PostToolUse"
    "PostToolUseFailure"
    "Stop"
    "StopFailure"
    "SubagentStart"
    "SubagentStop"
    "Notification"
    "Elicitation"
    "PreCompact"
    "PostCompact"
  ];

  mkClawdCommandHook = event: [
    {
      matcher = "";
      hooks = [
        {
          type = "command";
          command = "${clawdHookRunner} ${event}";
          async = true;
          timeout = 5;
        }
      ];
    }
  ];

  clawdHooks = lib.genAttrs clawdCommandEvents mkClawdCommandHook // {
    # Synchronous HTTP hook served by the running Clawd on Desk app; no script
    # on disk to guard, so it is simply omitted on hosts without the app.
    PermissionRequest = [
      {
        matcher = "";
        hooks = [
          {
            type = "http";
            url = "http://127.0.0.1:23333/permission";
            timeout = 600;
          }
        ];
      }
    ];
  };

  # ---------------------------------------------------------------------------
  # Herdr integration
  #
  # Herdr's CLI can mutate ~/.claude with `herdr integration install claude`;
  # keep the same hook declarative so settings.json stays owned by
  # home-manager. The hook asset comes from the pinned Herdr flake input, so an
  # input update also updates the installed integration script.
  herdrInstalled = lib.any (p: lib.getName p == "herdr") config.home.packages;
  herdrEnabled = herdrInstalled;

  herdrHookName = "herdr-agent-state.sh";
  herdrHookAsset = builtins.readFile "${inputs.herdr.outPath}/src/integration/assets/claude/${herdrHookName}";
  herdrHookScript = pkgs.writeShellScript "herdr-agent-state" herdrHookAsset;

  # Runtime guard: run the generated Herdr hook only inside a Herdr pane.
  # Otherwise consume stdin and exit successfully so a non-Herdr Claude session
  # never breaks. PATH is extended with Nix's Python because the upstream hook
  # intentionally shells out to `python3` for the socket JSON-RPC call.
  herdrHookRunner = pkgs.writeShellScript "herdr-claude-hook-runner" ''
    set -u
    action="''${1:-}"
    hook="${herdrHookScript}"
    export PATH="${lib.makeBinPath [ pkgs.python3 ]}:''${PATH:-}"
    if [ -n "$action" ] \
      && [ "''${HERDR_ENV:-}" = "1" ] \
      && [ -n "''${HERDR_SOCKET_PATH:-}" ] \
      && [ -n "''${HERDR_PANE_ID:-}" ] \
      && [ -x "$hook" ]; then
      exec "$hook" "$action"
    fi
    cat >/dev/null 2>/dev/null || true
    exit 0
  '';

  mkHerdrCommandHook = action: [
    {
      matcher = "";
      hooks = [
        {
          type = "command";
          command = "${herdrHookRunner} ${action}";
          async = true;
          timeout = 10;
        }
      ];
    }
  ];

  # Mirrors Herdr v0.6.6's Claude installer: prompt/tool activity is working,
  # permission prompts are blocked, stops are idle, and session end releases the
  # pane. PostToolUse/SubagentStop are intentionally not mapped because Herdr's
  # current integration avoids reviving an idle pane from recap/subagent events.
  herdrHooks = {
    SessionStart = mkHerdrCommandHook "idle";
    UserPromptSubmit = mkHerdrCommandHook "working";
    PreToolUse = mkHerdrCommandHook "working";
    PermissionRequest = mkHerdrCommandHook "blocked";
    Stop = mkHerdrCommandHook "idle";
    SessionEnd = mkHerdrCommandHook "release";
  };

  mergeHookSets = hookSets: lib.zipAttrsWith (_event: values: lib.concatLists values) hookSets;

  activeClaudeHooks = mergeHookSets (
    lib.optional herdrEnabled herdrHooks ++ lib.optional clawdEnabled clawdHooks
  );
in
{
  home.packages = [
    claudeCodex
    claudeCodexFast
    claudeMimo
  ];

  programs.claude-code = {
    enable = true;
    package = pkgs.claude-code;

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
    }
    # Declarative integrations, only on hosts that install the corresponding
    # package. Multiple integrations on the same event are concatenated.
    // lib.optionalAttrs (activeClaudeHooks != { }) { hooks = activeClaudeHooks; };

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
        args = [ "--stdio" ];
        extensionToLanguage = {
          ".py" = "python";
          ".pyi" = "python";
        };
      };
      ty = {
        command = lib.getExe pkgs.ty;
        args = [ "server" ];
        extensionToLanguage = {
          ".py" = "python";
          ".pyi" = "python";
        };
      };
      rust = {
        command = lib.getExe pkgs.rust-analyzer;
        args = [ ];
        extensionToLanguage = {
          ".rs" = "rust";
        };
      };
      nix = {
        command = lib.getExe pkgs.nixd;
        args = [ ];
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
