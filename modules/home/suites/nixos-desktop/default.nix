{
  config,
  lib,
  namespace,
  ...
}:
{
  options.${namespace}.suites.nixos-desktop = {
    enable = lib.mkEnableOption "NixOS Desktop Suite";
  };

  config =
    let
      cfg = config.${namespace}.suites.nixos-desktop;
    in
    lib.mkIf cfg.enable {
      nichijou.programs = {
        _1password.enable = true;
        firefox.enable = true;
        google-chrome.enable = true;
        kitty.enable = true;
        thunderbird.enable = true;
        vscode.enable = true;
        wezterm.enable = true;
        zed-editor.enable = true;
        zotero.enable = true;
      };
    };
}
