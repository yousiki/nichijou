{
  lib,
  perSystem,
  pkgs,
  ...
}:

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

    alt-tab-macos
    telegram-desktop

    brewCasks.chatgpt-atlas
    # brew-nix's Claude desktop cask also exposes bin/claude, which conflicts
    # with programs.claude-code in the Home Manager profile. Keep the app while
    # dropping its CLI shim; Claude Code remains the owner of bin/claude.
    (lib.hiPrio (
      brewCasks.claude.overrideAttrs (oldAttrs: {
        postInstall = (oldAttrs.postInstall or "") + ''
          rm -f "$out/bin/claude"
        '';
      })
    ))
    brewCasks.feishu
    brewCasks.keepingyouawake
    brewCasks.linearmouse
    brewCasks.linear
    brewCasks.tencent-meeting
    brewCasks.thaw
    brewCasks.zotero
  ];
}
