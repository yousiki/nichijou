{pkgs, ...}: {
  catppuccin.ghostty.enable = false;

  programs.ghostty = {
    enable = true;
    package =
      if pkgs.stdenv.isDarwin
      then pkgs.ghostty-bin
      else pkgs.ghostty;

    enableZshIntegration = true;
    settings = {
      font-family = "Maple Mono NF CN";
      font-size = 11;
      font-thicken = true;
      adjust-cell-height = 2;

      theme = "light:Catppuccin Frappe,dark:Catppuccin Mocha";
      unfocused-split-opacity = 0.85;
      background-opacity = 0.9;
      background-blur = 20;

      window-padding-x = 10;
      window-padding-y = 8;
      window-save-state = "always";

      cursor-style = "bar";
      cursor-style-blink = true;
      cursor-opacity = 0.8;

      mouse-hide-while-typing = true;
      copy-on-select = "clipboard";

      quick-terminal-screen = "mouse";
      quick-terminal-animation-duration = 0.15;

      shell-integration-features = "cursor,sudo,title,ssh-env,ssh-terminfo,path";
      scrollback-limit = 25000000;

      keybind = [
        "super+shift+arrow_left=previous_tab"
        "super+shift+arrow_right=next_tab"
        "super+shift+h=previous_tab"
        "super+shift+l=next_tab"
        "super+alt+h=goto_split:left"
        "super+alt+l=goto_split:right"
        "super+alt+k=goto_split:up"
        "super+alt+j=goto_split:down"
        "super+minus=decrease_font_size:1"
        "ctrl+backquote=toggle_quick_terminal"
        "super+shift+e=equalize_splits"
        "super+shift+f=toggle_split_zoom"
        "alt+backspace=text:\\x1b\\x7f"
        "shift+enter=text:\\n"
      ];
    };
  };
}
