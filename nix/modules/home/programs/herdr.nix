{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:

let
  cfg = config.programs.herdr;
  tomlFormat = pkgs.formats.toml { };

  settings = {
    onboarding = false;
  };

  # Herdr's CLI can mutate ~/.claude with `herdr integration install claude`;
  # keep the same hook declarative so settings.json stays owned by
  # home-manager. The hook asset comes from the pinned Herdr flake input, so an
  # input update also updates the installed integration script.
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
  herdrClaudeHooks = {
    SessionStart = mkHerdrCommandHook "idle";
    UserPromptSubmit = mkHerdrCommandHook "working";
    PreToolUse = mkHerdrCommandHook "working";
    PermissionRequest = mkHerdrCommandHook "blocked";
    Stop = mkHerdrCommandHook "idle";
    SessionEnd = mkHerdrCommandHook "release";
  };

in
{
  options.programs.herdr.enable = lib.mkEnableOption "Herdr";

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      home.packages = [
        pkgs.herdr
      ];

      xdg.configFile."herdr/config.toml" = {
        source = tomlFormat.generate "herdr-config.toml" settings;
        onChange = ''
          ${lib.getExe pkgs.herdr} server reload-config >/dev/null 2>&1 || true
        '';
      };
    })

    (lib.mkIf (cfg.enable && (config.programs.claude-code.enable or false)) {
      programs.claude-code.settings.hooks = herdrClaudeHooks;
    })
  ];
}
