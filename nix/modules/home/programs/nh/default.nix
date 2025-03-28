{
  lib,
  namespace,
  config,
  ...
}: let
  cfg = config.${namespace}.programs.nh;
in {
  options.${namespace}.programs.nh = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable nh.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.nh = {
      enable = true;
    };
  };
}
