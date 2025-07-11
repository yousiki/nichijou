{
  config,
  lib,
  namespace,
  ...
}:
{
  options.${namespace}.suites.darwin-desktop = {
    enable = lib.mkEnableOption "Darwin Desktop Suite";
  };

  config =
    let
      cfg = config.${namespace}.suites.darwin-desktop;
    in
    lib.mkIf cfg.enable {
      nichijou.programs = {
        _1password.enable = true;
        aerospace.enable = true;
        alt-tab.enable = true;
        cyberduck.enable = true;
        easydict.enable = true;
        google-chrome.enable = true;
        ice-bar.enable = true;
        iina.enable = true;
        keepingyouawake.enable = true;
        keka.enable = true;
        kitty.enable = true;
        maccy.enable = true;
        monitorcontrol.enable = true;
        mos.enable = true;
        raycast.enable = true;
        rectangle.enable = true;
        vscode.enable = true;
        warp-terminal.enable = true;
        wezterm.enable = true;
        zed-editor.enable = true;
        zotero.enable = true;
      };
    };
}
