{ pkgs, ... }:

{
  targets.darwin.linkApps.enable = true;

  home.packages = with pkgs; [
    raycast
    rectangle
    maccy
    iina
    obsidian
    brave
    _1password-gui
    monitorcontrol
    orbstack
    slack
    spotify
    zoom-us
    zed-editor

    brewCasks.chatgpt-atlas
    brewCasks.cloudflare-warp
    brewCasks.dockdoor
    brewCasks.keepingyouawake
    brewCasks.keka
    brewCasks.linearmouse
    brewCasks.thaw
    brewCasks.zotero
  ];
}
