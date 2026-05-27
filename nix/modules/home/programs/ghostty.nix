{ pkgs, ... }:

{
  programs.ghostty = {
    enable = true;
    package = pkgs.brewCasks.ghostty;

    enableZshIntegration = true;
    installBatSyntax = true;
    installVimSyntax = true;

    settings = {
      "font-family" = "Maple Mono NF CN";
      "font-size" = 14;

      "macos-option-as-alt" = true;
      "copy-on-select" = "clipboard";
      "clipboard-read" = "allow";
      "clipboard-write" = "allow";

      "scrollback-limit" = 10000000;
      "scrollbar" = "never";
      "mouse-hide-while-typing" = true;

      "window-padding-x" = 6;
      "window-padding-y" = 6;
      "macos-titlebar-style" = "transparent";
      "quit-after-last-window-closed" = true;
      "confirm-close-surface" = false;
    };
  };
}
