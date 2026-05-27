{ lib, pkgs, ... }:

let
  zedPackage = pkgs.zed-editor;
  zedCli = pkgs.writeShellApplication {
    name = "zed";
    text = ''
      exec ${lib.getExe' zedPackage "zeditor"} "$@"
    '';
  };
in
{
  home.packages = [
    zedCli
  ];

  catppuccin.zed = {
    enable = true;
    icons.enable = true;
  };

  programs.zed-editor = {
    enable = true;
    package = zedPackage;

    extensions = [
      "catppuccin"
      "catppuccin-icons"
      "nix"
    ];

    userSettings = {
      auto_update = false;

      telemetry = {
        diagnostics = false;
        metrics = false;
      };

      buffer_font_family = "Maple Mono NF CN";
      buffer_font_size = 14;

      ui_font_family = ".SystemUIFont";
      ui_font_size = 16;

      terminal = {
        font_family = "Maple Mono NF CN";
        font_size = 14;
        option_as_meta = true;
      };

      format_on_save = "on";
    };
  };

  home.sessionVariables = {
    EDITOR = "zed --wait";
    VISUAL = "zed --wait";
  };
}
