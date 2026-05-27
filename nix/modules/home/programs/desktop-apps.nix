{ pkgs, ... }:

{
  home.packages = with pkgs; [
    raycast
    rectangle
    maccy
    iina
    obsidian
    brave
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
