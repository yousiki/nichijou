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

  clawdPrefsPath = "${config.home.homeDirectory}/Library/Application Support/clawd-on-desk/clawd-prefs.json";
  clawdPrefsPatchFile = pkgs.writeText "clawd-prefs-home-manager-patch.json" (builtins.toJSON cfg.settings);
  clawdPrefsMergeScript = ../../../../scripts/clawd-prefs-merge.py;

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
      # State-only PermissionRequest hook: feed the event through Clawd's
      # notification state path so the pet animates, but leave Claude Code's
      # built-in terminal prompt in charge instead of opening a Clawd bubble.
      PermissionRequest = mkClawdCommandHook "Notification";
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

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {
        # Keep hook-driven pet/session animation, but suppress Clawd's floating
        # bubble cards and sounds so state changes only animate the desktop pet.
        manageClaudeHooksAutomatically = false;
        hideBubbles = true;
        notificationBubbleAutoCloseSeconds = 0;
        permissionBubbleAutoCloseSeconds = 0;
        soundMuted = true;
      };
      description = "Preference keys to merge into Clawd on Desk's mutable clawd-prefs.json on activation.";
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

    home.activation.patchClawdPrefs = lib.mkIf canInstall (lib.hm.dag.entryAfter ["writeBoundary"] ''
      prefs=${lib.escapeShellArg clawdPrefsPath}
      patch=${lib.escapeShellArg clawdPrefsPatchFile}

      $DRY_RUN_CMD mkdir -p "$(dirname "$prefs")"
      $DRY_RUN_CMD ${pkgs.python3}/bin/python3 ${clawdPrefsMergeScript} "$prefs" "$patch"
    '');

    programs.claude-code.settings.hooks = lib.mkIf canInstall clawdClaudeHooks;
  };
}
