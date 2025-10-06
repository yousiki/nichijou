{
  pkgs,
  ...
}:
{
  programs.zed-editor = {
    enable = true;
    package = if pkgs.stdenv.isDarwin then pkgs.emptyDirectory else pkgs.zed-zed-editor;
    extensions = [
      "astro"
      "catppuccin"
      "catppuccin-icons"
      "docker-compose"
      "dockerfile"
      "git-firefly"
      "html"
      "latex"
      "log"
      "lua"
      "make"
      "nix"
      "ruby"
      "swift"
      "toml"
      "vue"
      "xml"
    ];
    userSettings = {
      agent = {
        always_allow_tool_actions = true;
        play_sound_when_agent_done = true;
      };
      minimap.show = "auto";
      inlay_hints = {
        enabled = true;
        show_value_hints = true;
        show_type_hints = true;
        show_parameter_hints = true;
        show_other_hints = true;
        show_background = true;
      };
      diagnostics = {
        include_warnings = true;
        inline.enabled = true;
      };
      edit_predictions = {
        mode = "eager";
      };
      features.edit_prediction_provider = "copilot";
      indent_guides = {
        coloring = "indent_aware";
        background_coloring = "indent_aware";
      };
      current_line_highlight = "line";
      buffer_font_family = "Maple Mono NF CN";
      buffer_font_size = 14;
      ui_font_family = "Maple Mono NF CN";
      ui_font_size = 15;
      agent_font_size = 15;
      terminal = {
        font_family = "Maple Mono NF CN";
        font_size = 12;
        copy_on_select = true;
      };
      use_smartcase_search = true;
      tabs = {
        file_icons = true;
        git_status = true;
      };
      telemetry = {
        diagnostics = false;
        metrics = false;
      };
      vim_mode = true;
      base_keymap = "VSCode";
      restore_on_startup = "none";
      theme = {
        mode = "system";
        light = "Catppuccin Frappé";
        dark = "Catppuccin Mocha";
      };
      icon_theme = {
        mode = "system";
        light = "Catppuccin Frappé";
        dark = "Catppuccin Mocha";
      };
      languages = {
        Python = {
          language_servers = [
            "basedpyright"
            "ty"
            "ruff"
          ];
          formatter = [
            {
              language_server.name = "ruff";
            }
          ];
        };
      };
    };
  };

  catppuccin.zed.enable = false;
}
