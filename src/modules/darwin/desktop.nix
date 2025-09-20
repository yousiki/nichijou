_: {
  flake.modules =
    let
      cond =
        { config, lib, ... }:
        let
          tags = config.manifest.tags or [ ];
        in
        lib.elem "desktop" tags;

      darwinModule =
        { lib, ... }@args:
        lib.mkIf (cond args) {
          homebrew.casks = [
            "1password"
            "adobe-creative-cloud"
            "alt-tab"
            "chatgpt"
            "cherry-studio"
            "clash-party"
            "claude"
            "claude-code"
            "conductor"
            "cyberduck"
            "easydict"
            "element"
            "feishu"
            "firefox"
            "font-caskaydia-cove-nerd-font"
            "font-maple-mono-nf-cn"
            "google-chrome"
            "iina"
            "jordanbaird-ice@beta"
            "keepingyouawake"
            "keka"
            "kitty"
            "logi-options+"
            "maccy"
            "microsoft-excel"
            "microsoft-powerpoint"
            "microsoft-word"
            "monitorcontrol"
            "mos"
            "orbstack"
            "pearcleaner"
            "prettyclean"
            "qq"
            "raycast"
            "rectangle"
            "spotify"
            "tailscale-app"
            "tencent-meeting"
            "thunderbird"
            "transmission"
            "visual-studio-code"
            "warp"
            "wechat"
            "zed"
            "zoom"
            "zotero"
          ];
        };
    in
    {
      darwin.darwin-desktop = darwinModule;
    };
}
