{
  lib,
  pkgs,
  namespace,
  config,
  system,
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
    home.packages = with pkgs; [
      zed-editor
    ];

    nixGL.vulkan.enable = system == "x86_64-linux" || system == "aarch64-linux";
  };
}
