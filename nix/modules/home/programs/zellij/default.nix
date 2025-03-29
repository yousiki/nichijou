{
  lib,
  namespace,
  config,
  ...
}:
let
  cfg = config.${namespace}.programs.zellij;
in
{
  options.${namespace}.programs.zellij = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable zellij.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.zellij = {
      enable = true;
      enableBashIntegration = false;
      enableZshIntegration = false;
    };
  };
}
