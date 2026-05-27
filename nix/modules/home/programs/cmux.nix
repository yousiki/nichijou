{ lib, pkgs, ... }:

let
  cmuxConfig = (pkgs.formats.json { }).generate "cmux.json" {
    "$schema" = "https://raw.githubusercontent.com/manaflow-ai/cmux/main/web/data/cmux.schema.json";
    schemaVersion = 1;

    app = {
      appearance = "dark";
      appIcon = "dark";
      confirmQuit = "dirty-only";
      newWorkspacePlacement = "afterCurrent";
      openMarkdownInCmuxViewer = true;
      openSupportedFilesInCmux = true;
      sendAnonymousTelemetry = false;
      workspaceInheritWorkingDirectory = true;
    };

    terminal = {
      copyOnSelect = true;
      showScrollBar = false;
      autoResumeAgentSessions = true;
    };

    notifications = {
      sound = "none";
      paneFlash = false;
    };

    sidebar = {
      branchLayout = "inline";
    };

    sidebarAppearance = {
      matchTerminalBackground = true;
    };

    automation = {
      socketControlMode = "cmuxOnly";
      claudeBinaryPath = lib.getExe pkgs.claude-code;
      ripgrepBinaryPath = lib.getExe pkgs.ripgrep;
      suppressSubagentNotifications = true;
    };
  };
in
{
  targets.darwin.copyApps.enable = true;

  home.packages = [
    pkgs.brewCasks.cmux
  ];

  xdg.configFile."cmux/cmux.json".source = cmuxConfig;
}
