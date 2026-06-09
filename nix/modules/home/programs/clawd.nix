{
  lib,
  pkgs,
  config,
  perSystem ? null,
  ...
}: let
  cfg = config.programs.clawd;
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  canInstall = isDarwin && cfg.package != null;

  # Clawd on Desk normally mutates ~/.claude/settings.json at runtime; keep the
  # same integration declarative so Claude Code settings stay owned by
  # home-manager. The hook path comes from the installed app package, so package
  # updates also update the integration script.
  clawdHookScript =
    "${cfg.package}/Applications/Clawd on Desk.app"
    + "/Contents/Resources/app.asar.unpacked/hooks/clawd-hook.js";

  # Runtime guard: run the Clawd hook with Bun only when the installed app still
  # has the hook asset on disk. If the app was removed out-of-band the wrapper
  # exits successfully and never breaks the calling Claude Code session.
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

  clawdClaudeHooks =
    lib.genAttrs clawdCommandEvents mkClawdCommandHook
    // {
      # Synchronous HTTP hook served by the running Clawd on Desk app.
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
in {
  options.programs.clawd = {
    enable = lib.mkEnableOption "Clawd on Desk";

    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default =
        if isDarwin && perSystem != null
        then perSystem.self.clawd-on-desk
        else null;
      defaultText = lib.literalExpression "perSystem.self.clawd-on-desk";
      description = "Clawd on Desk package to install.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = isDarwin;
        message = "programs.clawd is only supported on Darwin.";
      }
      {
        assertion = cfg.package != null;
        message = "programs.clawd.package must be set when perSystem.self.clawd-on-desk is unavailable.";
      }
    ];

    home.packages = lib.optionals canInstall [
      cfg.package
    ];

    programs.claude-code.settings.hooks = lib.mkIf canInstall clawdClaudeHooks;
  };
}
