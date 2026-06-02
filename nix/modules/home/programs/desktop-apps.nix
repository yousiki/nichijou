{ perSystem, pkgs, ... }:

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
    wechat
    zoom-us

    perSystem.self.clawd-on-desk

    brewCasks.chatgpt-atlas
    brewCasks.dockdoor
    brewCasks.feishu
    brewCasks.keepingyouawake
    brewCasks.linearmouse
    brewCasks.microsoft-outlook
    brewCasks.tencent-meeting
    brewCasks.thaw
    brewCasks.zotero
  ];
}
