{ pkgs, ... }:

let
  ohMyOpenAgentConfig = (pkgs.formats.json { }).generate "oh-my-openagent.json" {
    "$schema" =
      "https://raw.githubusercontent.com/code-yeongyu/oh-my-openagent/dev/assets/oh-my-opencode.schema.json";

    agents = {
      sisyphus = {
        model = "openai/gpt-5.5-fast";
        variant = "medium";
        fallback_models = [
          "xiaomi/mimo-v2.5-pro"
          "opencode/big-pickle"
        ];
      };
      hephaestus = {
        model = "openai/gpt-5.5-fast";
        variant = "medium";
        fallback_models = [
          "xiaomi/mimo-v2.5-pro"
        ];
      };
      oracle = {
        model = "openai/gpt-5.5-fast";
        variant = "high";
        fallback_models = [
          "xiaomi/mimo-v2.5-pro"
        ];
      };
      librarian = {
        model = "openai/gpt-5.4-mini-fast";
        fallback_models = [
          "openai/gpt-5.4-nano"
          "xiaomi/mimo-v2.5"
          "opencode/mimo-v2.5-free"
          "opencode/deepseek-v4-flash-free"
        ];
      };
      explore = {
        model = "openai/gpt-5.4-mini-fast";
        fallback_models = [
          "openai/gpt-5.4-nano"
          "xiaomi/mimo-v2.5"
          "opencode/mimo-v2.5-free"
          "opencode/deepseek-v4-flash-free"
        ];
      };
      "multimodal-looker" = {
        model = "openai/gpt-5.5-fast";
        variant = "medium";
        fallback_models = [
          "openai/gpt-5-nano"
          "xiaomi/mimo-v2.5"
        ];
      };
      prometheus = {
        model = "openai/gpt-5.5-fast";
        variant = "high";
        fallback_models = [
          "xiaomi/mimo-v2.5-pro"
        ];
      };
      metis = {
        model = "openai/gpt-5.5-fast";
        variant = "high";
        fallback_models = [
          "xiaomi/mimo-v2.5-pro"
        ];
      };
      momus = {
        model = "openai/gpt-5.5-fast";
        variant = "xhigh";
        fallback_models = [
          "xiaomi/mimo-v2.5-pro"
        ];
      };
      atlas = {
        model = "openai/gpt-5.5-fast";
        variant = "medium";
        fallback_models = [
          "xiaomi/mimo-v2.5-pro"
          "xiaomi/mimo-v2.5"
          "opencode/mimo-v2.5-free"
          "opencode/big-pickle"
        ];
      };
      "sisyphus-junior" = {
        model = "openai/gpt-5.5-fast";
        variant = "medium";
        fallback_models = [
          "xiaomi/mimo-v2.5-pro"
          "xiaomi/mimo-v2.5"
          "opencode/mimo-v2.5-free"
          "opencode/big-pickle"
        ];
      };
    };

    categories = {
      "visual-engineering" = {
        model = "github-copilot/gemini-3.1-pro-preview";
        variant = "high";
        fallback_models = [
          {
            model = "openai/gpt-5.5-fast";
            variant = "xhigh";
          }
          "xiaomi/mimo-v2.5"
        ];
      };
      ultrabrain = {
        model = "openai/gpt-5.5-fast";
        variant = "xhigh";
        fallback_models = [
          "xiaomi/mimo-v2.5-pro"
        ];
      };
      deep = {
        model = "openai/gpt-5.5-fast";
        variant = "medium";
        fallback_models = [
          "xiaomi/mimo-v2.5-pro"
          "opencode/big-pickle"
        ];
      };
      artistry = {
        model = "github-copilot/gemini-3.1-pro-preview";
        variant = "high";
        fallback_models = [
          {
            model = "openai/gpt-5.5-fast";
            variant = "high";
          }
          "xiaomi/mimo-v2.5-pro"
        ];
      };
      quick = {
        model = "openai/gpt-5.4-mini";
        fallback_models = [
          "openai/gpt-5.3-codex-spark"
          "xiaomi/mimo-v2.5"
          "opencode/deepseek-v4-flash-free"
        ];
      };
      "unspecified-low" = {
        model = "openai/gpt-5.5-fast";
        variant = "medium";
        fallback_models = [
          "xiaomi/mimo-v2.5-pro"
          {
            model = "openai/gpt-5.3-codex";
            variant = "medium";
          }
          "openai/gpt-5.4-mini"
          "openai/gpt-5.3-codex-spark"
          "opencode/deepseek-v4-flash-free"
        ];
      };
      "unspecified-high" = {
        model = "openai/gpt-5.5-fast";
        variant = "xhigh";
        fallback_models = [
          "xiaomi/mimo-v2.5-pro"
        ];
      };
      writing = {
        model = "openai/gpt-5.5-fast";
        fallback_models = [
          "xiaomi/mimo-v2.5-pro"
          "opencode/deepseek-v4-flash-free"
        ];
      };
    };
  };
in
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
      mcp = {
        deepwiki = {
          type = "remote";
          url = "https://mcp.deepwiki.com/mcp";
          enabled = true;
          oauth = false;
        };
        nixos = {
          type = "local";
          command = [
            "nix"
            "run"
            "github:utensils/mcp-nixos"
            "--"
          ];
          enabled = true;
        };
      };
      formatter.nixfmt.command = [
        "nix"
        "run"
        "nixpkgs#nixfmt"
        "--"
        "$FILE"
      ];
      lsp.nixd.command = [
        "nix"
        "run"
        "nixpkgs#nixd"
        "--"
      ];
      provider.openai.options = {
        baseURL = "http://127.0.0.1:8317/v1";
        apiKey = "{file:/Users/yousiki/.config/opencode/opencode-api-key}";
      };
      tmux = {
        enabled = true;
        layout = "main-vertical";
        main_pane_size = 60;
        main_pane_min_width = 120;
        agent_pane_min_width = 40;
      };
      share = "manual";
    };

    tui = {
      "$schema" = "https://opencode.ai/tui.json";
      mouse = true;
      scroll_acceleration.enabled = true;
    };
  };

  xdg.configFile."opencode/oh-my-openagent.json".source = ohMyOpenAgentConfig;
}
