{ pkgs, ... }:

let
  onePasswordGui = pkgs._1password-gui.overrideAttrs (_: {
    version = "8.12.21";
    # TODO: Drop this when nixpkgs updates the aarch64-darwin 1Password hash.
    src = pkgs.fetchurl {
      url = "https://downloads.1password.com/mac/1Password-8.12.21-aarch64.zip";
      hash = "sha256-WrWbGzBK65tVNl9Dc3OnJURiPpfbNLOYUJcVT0ETaAs=";
    };
  });
in
{
  targets.darwin.linkApps.enable = true;

  home.packages = with pkgs; [
    raycast
    rectangle
    maccy
    iina
    obsidian
    brave
    onePasswordGui
    monitorcontrol
    orbstack
    keka
    slack
    spotify
    zoom-us
    zed-editor

    brewCasks.chatgpt-atlas
    brewCasks.dockdoor
    brewCasks.keepingyouawake
    brewCasks.linearmouse
    brewCasks.thaw
    brewCasks.zotero
  ];
}
