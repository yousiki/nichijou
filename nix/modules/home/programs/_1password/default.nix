{
  lib,
  pkgs,
  namespace,
  config,
  ...
}:
let
  cfg = config.${namespace}.programs._1password;
in
{
  options.${namespace}.programs._1password = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable 1Password.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      _1password-cli
      _1password-gui
    ];
  };
}
