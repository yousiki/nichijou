{ lib, pkgs, ... }:

{
  programs.ghostty = {
    enable = true;
    package = pkgs.brewCasks.ghostty;

    enableZshIntegration = false;
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

  programs.zsh.initContent = lib.mkOrder 1000 ''
    # cmux exposes GhosttyKit variables but keeps its bundled integration in CMUX_SHELL_INTEGRATION_DIR.
    if [[ -n ''${GHOSTTY_RESOURCES_DIR:-} && -r "''${GHOSTTY_RESOURCES_DIR}/shell-integration/zsh/ghostty-integration" ]]; then
      source "''${GHOSTTY_RESOURCES_DIR}/shell-integration/zsh/ghostty-integration"
    elif [[ "''${CMUX_LOAD_GHOSTTY_ZSH_INTEGRATION:-0}" == "1" && -n ''${CMUX_SHELL_INTEGRATION_DIR:-} && -r "''${CMUX_SHELL_INTEGRATION_DIR}/ghostty-integration.zsh" ]]; then
      source "''${CMUX_SHELL_INTEGRATION_DIR}/ghostty-integration.zsh"
    fi
  '';
}
