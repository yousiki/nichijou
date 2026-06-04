{
  lib,
  perSystem,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    alt-tab-macos
    brave
    iina
    keka
    maccy
    monitorcontrol
    obsidian
    orbstack
    raycast
    rectangle
    slack
    spotify
    telegram-desktop
    wechat
    zoom-us

    perSystem.self.clawd-on-desk

    brewCasks.chatgpt-atlas
    brewCasks.feishu
    brewCasks.keepingyouawake
    brewCasks.linearmouse
    brewCasks.linear
    brewCasks.tencent-meeting
    brewCasks.thaw
    brewCasks.zotero
  ];
}
