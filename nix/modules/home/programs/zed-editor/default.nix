{
  lib,
  pkgs,
  namespace,
  config,
  ...
}:
let
  cfg = config.${namespace}.programs.zed-editor;
in
{
  options.${namespace}.programs.zed-editor = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable Zed Editor.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.optionals pkgs.stdenv.isLinux (
      with pkgs;
      [
        zed-editor
      ]
    );

    nixGL.vulkan.enable = pkgs.stdenv.isLinux;
  };
}
