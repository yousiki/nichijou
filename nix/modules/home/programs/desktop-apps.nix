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

    brewCasks.chatgpt-atlas
    brewCasks.dockdoor
    brewCasks.feishu
    brewCasks.keepingyouawake
    brewCasks.linearmouse
    brewCasks.tencent-meeting
    brewCasks.thaw
    brewCasks.zotero
  ];
}
