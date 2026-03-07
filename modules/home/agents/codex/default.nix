{pkgs, ...}: {
  programs.codex = {
    enable = true;
    package = pkgs.codex;
    enableMcpIntegration = true;
    settings = {
      model = "gpt-5.4";
      model_reasoning_effort = "medium";
      model_personality = "pragmatic";
      sandbox_mode = "workspace-write";
      shell_environment_policy = {
        "inherit" = "core";
        set = {
          CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
        };
      };
    };
  };

  # Keep a stable executable path on macOS so Codex permissions survive upgrades.
  home.file.".local/bin/codex".source = "${pkgs.codex}/bin/codex";
  home.sessionPath = ["$HOME/.local/bin"];
}
