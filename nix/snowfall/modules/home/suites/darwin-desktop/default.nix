{
  config,
  lib,
  namespace,
  ...
}:
{
  options.${namespace}.suites.darwin-desktop = {
    enable = lib.mkEnableOption "darwin desktop suite";
  };

  config = lib.mkIf config.${namespace}.suites.darwin-desktop.enable {
    ${namespace}.programs = builtins.listToAttrs (
      builtins.map
        (program: {
          name = program;
          value = {
            enable = true;
          };
        })
        [
          "_1password-gui"
          "alt-tab-macos"
          "baidunetdisk"
          "chatgpt"
          "claude"
          "cyberduck"
          "easydict"
          "feishu"
          "firefox"
          "google-chrome"
          "ice-bar"
          "iina"
          "keepingyouawake"
          "keka"
          "kitty"
          "maccy"
          "mihomo-party"
          "monitorcontrol"
          "mos"
          "qq"
          "raycast"
          "rectangle"
          "tencent-meeting"
          "thunderbird"
          "vscode"
          "warp-terminal"
          "wechat"
          "zed"
          "zoom-us"
          "zotero"
        ]
    );
  };
}
