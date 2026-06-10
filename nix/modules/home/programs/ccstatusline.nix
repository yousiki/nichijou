{
  lib,
  pkgs,
  perSystem,
  ...
}: let
  ccstatusline = perSystem.self.ccstatusline;

  mocha = {
    blue = "hex:89b4fa";
    green = "hex:a6e3a1";
    mauve = "hex:cba6f7";
    peach = "hex:fab387";
    subtext0 = "hex:a6adc8";
  };

  # ccstatusline's TUI can write both ~/.config/ccstatusline/settings.json and
  # ~/.claude/settings.json. Keep both under Home Manager instead: the renderer
  # below points at this generated config, and Claude's statusLine command is
  # declared in programs.claude-code.settings.
  settings = (pkgs.formats.json {}).generate "ccstatusline-settings.json" {
    version = 3;
    flexMode = "full";
    compactThreshold = 60;
    colorLevel = 3;
    defaultPadding = " ";
    inheritSeparatorColors = false;
    globalBold = false;
    gitCacheTtlSeconds = 5;
    minimalistMode = true;

    powerline = {
      enabled = false;
      separators = [""];
      separatorInvertBackground = [false];
      startCaps = [];
      endCaps = [];
      autoAlign = false;
      continueThemeAcrossLines = false;
    };

    installation = {
      method = "self-managed";
      packageManager = "bun";
    };

    lines = [
      [
        {
          id = "model";
          type = "model";
          color = mocha.blue;
          bold = false;
          rawValue = true;
        }
        {
          id = "flex-1";
          type = "flex-separator";
        }
        {
          id = "effort";
          type = "thinking-effort";
          color = mocha.mauve;
          bold = false;
          rawValue = true;
        }
        {
          id = "flex-2";
          type = "flex-separator";
        }
        {
          id = "ctx";
          type = "context-percentage";
          color = mocha.peach;
          bold = false;
          rawValue = true;
        }
        {
          id = "flex-3";
          type = "flex-separator";
        }
        {
          id = "git-branch";
          type = "git-branch";
          color = mocha.green;
          bold = false;
          rawValue = true;
        }
        {
          id = "flex-4";
          type = "flex-separator";
        }
        {
          id = "cwd";
          type = "current-working-dir";
          color = mocha.subtext0;
          bold = false;
          rawValue = true;
          metadata = {
            segments = "2";
          };
        }
      ]
    ];
  };
in {
  home.packages = [
    ccstatusline
  ];

  xdg.configFile."ccstatusline/settings.json".source = settings;

  programs.claude-code.settings.statusLine = {
    type = "command";
    command = "${lib.getExe ccstatusline} --config ${settings}";
    padding = 0;
    refreshInterval = 10;
    hideVimModeIndicator = true;
  };
}
