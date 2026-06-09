{
  lib,
  pkgs,
  ...
}: let
  ghosttyPackage =
    if pkgs.stdenv.hostPlatform.isDarwin
    then
      lib.attrByPath [
        "brewCasks"
        "ghostty"
      ]
      pkgs.ghostty
      pkgs
    else pkgs.ghostty;
in {
  programs.ghostty = {
    enable = true;
    package = ghosttyPackage;

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
    if [[ -n ''${GHOSTTY_RESOURCES_DIR:-} && -r "''${GHOSTTY_RESOURCES_DIR}/shell-integration/zsh/ghostty-integration" ]]; then
      source "''${GHOSTTY_RESOURCES_DIR}/shell-integration/zsh/ghostty-integration"
    fi
  '';
}
