# Home-manager module to enable C++ programming language support.
{
  config,
  lib,
  namespace,
  pkgs,
  ...
}: let
  cfg = config.${namespace}.develop.cxx;
in {
  options.${namespace}.develop.cxx = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable C++ programming language support.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Install required packages.
    home.packages = with pkgs; [
      clang
      clang-tools
      cmake
      gnumake
    ];
  };
}
