{
  lib,
  pkgs,
  namespace,
  config,
  ...
}: let
  cfg = config.${namespace}.programs.bottom;
in {
  options.${namespace}.programs.bottom = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable bottom.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.bottom = {
      enable = true;
      package = pkgs.bottom;
    };

    home.shellAliases = let
      bottom = lib.getExe config.programs.bottom.package;
    in {
      bottom = lib.mkForce "${bottom}";
    };
  };
}
