{
  lib,
  pkgs,
  namespace,
  config,
  ...
}:
let
  cfg = config.${namespace}.programs.duf;
in
{
  options.${namespace}.programs.duf = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable duf.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      duf
    ];
  };
}
