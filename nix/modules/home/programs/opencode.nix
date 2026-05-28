{ pkgs, ... }:

{
  programs.opencode = {
    enable = true;
    package = pkgs.opencode;

    settings = {
      "$schema" = "https://opencode.ai/config.json";
      autoupdate = false;
      share = "manual";
    };

    tui = {
      "$schema" = "https://opencode.ai/tui.json";
      mouse = true;
    };
  };
}
