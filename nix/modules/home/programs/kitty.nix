{ pkgs, ... }:

{
  programs.kitty = {
    enable = true;
    package = pkgs.kitty;

    font = {
      name = "Maple Mono NF CN";
      size = 14;
    };

    settings = {
      macos_option_as_alt = "both";
      macos_quit_when_last_window_closed = "yes";
      confirm_os_window_close = 0;
      window_padding_width = 6;
      hide_window_decorations = "titlebar-only";
      shell_integration = "enabled";
      copy_on_select = "clipboard";
      scrollback_lines = 10000;
      enable_audio_bell = false;
    };
  };
}
