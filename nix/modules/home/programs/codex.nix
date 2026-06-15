{
  config,
  lib,
  pkgs,
  ...
}: let
  # The codex Home Manager module links config.toml read-only into the Nix
  # store. Codex, however, persists runtime state back into the very same file
  # (folder trust levels, NUX counters, plugin/hook trust hashes, ...), so a
  # read-only symlink makes every such write fail and codex errors constantly.
  #
  # We therefore keep the declarative settings below, but stop Home Manager from
  # linking the file and instead merge the generated settings into a writable
  # copy on activation, preserving whatever runtime state codex has written.
  configFile = "${lib.removePrefix config.home.homeDirectory config.xdg.configHome}/codex/config.toml";
  targetPath = "${config.xdg.configHome}/codex/config.toml";

  pythonWithToml = pkgs.python3.withPackages (ps: [ps.tomlkit]);

  mergeScript = pkgs.writeText "codex-config-merge.py" ''
    import sys
    from pathlib import Path

    import tomlkit

    target = Path(sys.argv[1])
    declared = tomlkit.parse(Path(sys.argv[2]).read_text())

    existing = ""
    if target.is_symlink():
        # Leftover read-only symlink from a previous generation: read its
        # content, then drop the link so we can write a real file in its place.
        try:
            existing = target.read_text()
        except OSError:
            existing = ""
        target.unlink()
    elif target.exists():
        existing = target.read_text()

    doc = tomlkit.parse(existing) if existing.strip() else tomlkit.document()

    def deep_merge(dst, src):
        for key, val in src.items():
            cur = dst.get(key)
            if hasattr(cur, "items") and hasattr(val, "items"):
                deep_merge(cur, val)
            else:
                dst[key] = val

    # Nix-declared keys win; codex's runtime keys are preserved.
    deep_merge(doc, declared)

    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(tomlkit.dumps(doc))
  '';
in {
  programs.codex = {
    enable = true;

    enableMcpIntegration = true;

    settings = {
      # Model + provider
      model = "gpt-5.5";
      model_provider = "cliproxyapi";
      model_reasoning_effort = "high";
      plan_mode_reasoning_effort = "xhigh";
      service_tier = "default";

      # Behaviour
      approval_policy = "never";
      approvals_reviewer = "guardian_subagent";
      sandbox_mode = "danger-full-access";
      network_access = "enabled";
      personality = "pragmatic";
      supports_websockets = true;
      suppress_unstable_features_warning = true;

      model_providers.cliproxyapi = {
        name = "cliproxyapi";
        base_url = "http://127.0.0.1:8317/v1";
        env_key = "CLIPROXYAPI_API_KEY";
        wire_api = "responses";
        requires_openai_auth = false;
        request_max_retries = 4;
        stream_max_retries = 5;
        stream_idle_timeout_ms = 600000;
      };

      tui = {
        theme = "catppuccin-mocha";
        status_line_use_colors = true;
        status_line = [
          "model-with-reasoning"
          "current-dir"
          "model"
          "project-name"
          "git-branch"
          "pull-request-number"
          "branch-changes"
          "context-remaining"
          "fast-mode"
          "task-progress"
        ];
      };

      features = {
        goals = true;
        unified_exec = true;
        child_agents_md = true;
        multi_agent = true;
        hooks = true;
        plugin_hooks = true;
        plugins = true;
        terminal_resize_reflow = true;
        memories = true;
        network_proxy = true;
        mentions_v2 = true;
        prevent_idle_sleep = true;
        enable_fanout = true;
        request_permissions_tool = true;
        exec_permission_approvals = true;
        realtime_conversation = true;
        enable_mcp_apps = true;
        auth_elicitation = true;
        remote_compaction_v2 = true;

        multi_agent_v2 = {
          enabled = false;
          max_concurrent_threads_per_session = 10000;
        };
      };

      notice = {
        hide_world_writable_warning = true;
        hide_full_access_warning = true;
      };
    };
  };

  # Replace the read-only symlink with a writable, merge-managed copy.
  home.file."${configFile}".enable = lib.mkForce false;

  home.activation.codexWritableConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run ${pythonWithToml}/bin/python3 ${mergeScript} \
      ${lib.escapeShellArg targetPath} \
      ${config.home.file."${configFile}".source}
  '';
}
