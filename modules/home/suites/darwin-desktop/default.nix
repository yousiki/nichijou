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
          "monitorcontrol"
          "mos"
          "prettyclean"
          "qq"
          "raycast"
          "rectangle"
          "tencent-meeting"
          "thunderbird"
          "vscode"
          "wechat"
          "zed"
          "zoom-us"
          "zotero"
        ]
    );
  };
}
