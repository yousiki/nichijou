{ pkgs, ... }:

{
  programs.opencode = {
    enable = true;
    package = pkgs.opencode;

    settings = {
      "$schema" = "https://opencode.ai/config.json";
      autoupdate = false;
      plugin = [
        "oh-my-openagent@latest"
      ];
      provider.openai.options = {
        baseURL = "http://127.0.0.1:8317/v1";
        apiKey = "{file:/Users/yousiki/.config/opencode/opencode-api-key}";
      };
      share = "manual";
    };

    tui = {
      "$schema" = "https://opencode.ai/tui.json";
      mouse = true;
      scroll_acceleration.enabled = true;
    };
  };
}
