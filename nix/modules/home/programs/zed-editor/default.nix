{
  lib,
  pkgs,
  namespace,
  config,
  system,
  ...
}:
let
  cfg = config.${namespace}.programs.zed-editor;
in
{
  options.${namespace}.programs.zed-editor = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable Zed Editor.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable and configure Zed Editor.
    programs.zed-editor = {
      enable = true;
      extensions = [
        "catppuccin"
        "catppuccin-icons"
        "docker-compose"
        "dockerfile"
        "nix"
        "ruff"
        "toml"
      ];
      extraPackages = with pkgs; [
        nixd
        nil
      ];
      userSettings = {
        auto_update = false;
        buffer_font_family = "CaskaydiaCove Nerd Font Mono";
        buffer_font_size = 13;
        current_line_highlight = "line";
        diagnostics = {
          include_warnings = true;
          inline = {
            enabled = true;
          };
        };
        ensure_final_newline_on_save = true;
        features = {
          edit_prediction_provider = "copilot";
        };
        file_scan_exclusions = [
          "**/__pycache__"
          "**/.DS_Store"
          "**/.git"
          "**/.ropeproject"
          "**/.ruff_cache"
          "**/.svn"
          "**/.venv"
          "**/Thumbs.db"
        ];
        edit_predictions = {
          disabled_globs = [
            "**/*.cert"
            "**/*.crt"
            "**/*.key"
            "**/*.pem"
            "**/.dev.vars"
            "**/.env*"
            "**/secrets.yml"
            "**/secrets/**"
          ];
        };
        indent_guides = {
          enabled = true;
          background_coloring = "indent_aware";
          coloring = "indent_aware";
        };
        inlay_hints = {
          enabled = true;
        };
        relative_line_numbers = true;
        remove_trailing_whitespace_on_save = true;
        restore_on_startup = "none";
        show_edit_predictions = true;
        show_whitespaces = "selection";
        soft_wrap = "editor_width";
        tab_size = 2;
        tabs = {
          file_icons = true;
          git_status = true;
        };
        terminal = {
          copy_on_select = true;
          font_family = "CaskaydiaCove Nerd Font Mono";
          font_size = 12;
        };
        ui_font_family = "CaskaydiaCove Nerd Font Propo";
        ui_font_size = 15;
        use_smartcase_search = true;
        vim_mode = true;
      };
      userKeymaps = [
        {
          bindings = {
            "j j" = "vim::NormalBefore";
            "j k" = "vim::NormalBefore";
            "k k" = "vim::NormalBefore";
          };
          context = "vim_mode == insert";
        }
        {
          bindings = {
            "ctrl-h" = "workspace::ActivatePaneLeft";
            "ctrl-j" = "workspace::ActivatePaneDown";
            "ctrl-k" = "workspace::ActivatePaneUp";
            "ctrl-l" = "workspace::ActivatePaneRight";
          };
        }
      ];
    };

    nixGL.vulkan.enable = system == "x86_64-linux" || system == "aarch64-linux";
  };
}
