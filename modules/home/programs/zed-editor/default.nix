{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.zed-editor = {
    enable = lib.mkEnableOption "Zed Editor";
  };

  config =
    let
      cfg = config.${namespace}.programs.zed-editor;
    in
    lib.mkIf cfg.enable {
      programs.zed-editor = {
        enable = true;
        package = pkgs.zed-editor;
        extensions = [
          "astro"
          "catppuccin"
          "catppuccin-icons"
          "csv"
          "docker-compose"
          "dockerfile"
          "git-firefly"
          "html"
          "latex"
          "log"
          "lua"
          "make"
          "nix"
          "ruff"
          "toml"
          "vue"
        ];
        extraPackages = with pkgs; [
          nil
          nixd
          nixfmt-rfc-style
          nodejs
          ruff
          rust-analyzer
          rustfmt
        ];
        userSettings = {
          auto_update = false;
          buffer_font_family = "CaskaydiaCove Nerd Font Mono";
          buffer_font_size = 13;
          ui_font_family = "CaskaydiaCove Nerd Font Mono";
          ui_font_size = 14;
          agent_font_size = 14;
          terminal = {
            font_family = "CaskaydiaCove Nerd Font Mono";
            font_size = 12;
            copy_on_select = true;
          };
          current_line_highlight = "line";
          diagnostics = {
            include_warnings = true;
            inline.enabled = true;
          };
          edit_predictions.mode = "subtle";
          features.edit_prediction_provider = "copilot";
          indent_guides = {
            coloring = "indent_aware";
            background_coloring = "indent_aware";
          };
          inlay_hints = {
            enabled = true;
            show_type_hints = true;
            show_parameter_hints = true;
            show_other_hints = true;
            show_background = true;
          };
          minimap.show = "auto";
          restore_on_startup = "none";
          soft_wrap = "editor_width";
          tab_size = 2;
          tabs = {
            file_icons = true;
            git_status = true;
          };
          use_smartcase_search = true;
          vim_mode = true;
          file_scan_exclusions = [
            "**/.DS_Store"
            "**/.classpath"
            "**/.git"
            "**/.hg"
            "**/.jj"
            "**/.pytest_cache"
            "**/.ropeproject"
            "**/.ruff_cache"
            "**/.svn"
            "**/.venv"
            "**/Thumbs.db"
            "**/__pycache__"
          ];
          languages = {
            Nix = {
              formatter = "language_server";
              format_on_save = "on";
              language_servers = [
                "nil"
                "nixd"
              ];
            };
            Python = {
              formatter = "language_server";
              language_servers = [
                "ruff"
                "pyright"
              ];
            };
            Rust = {
              tab_size = 4;
            };
          };
          lsp = {
            nil.settings = {
              formatting.command = [ "nixfmt" ];
              nix.flake = {
                autoArchive = true;
                nixpkgsInputName = "nixpkgs";
              };
            };
            nixd.settings = {
              formatting.command = [ "nixfmt" ];
              nixpkgs.expr = "import <nixpkgs> {}";
            };
          };
          agent =
            let
              claude = {
                provider = "copilot_chat";
                model = "claude-sonnet-4";
              };
              o4-mini = {
                provider = "copilot_chat";
                model = "o4-mini";
              };
            in
            {
              enabled = true;
              version = "2";
              always_allow_tool_actions = true;
              play_sound_when_agent_done = true;
              default_profile = "write";
              default_model = claude;
              commit_message_model = claude;
              inline_assistant_model = o4-mini;
              thread_summary_model = o4-mini;
            };
        };
      };
    };
}
