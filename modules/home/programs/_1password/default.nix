{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs._1password = {
    enable = lib.mkEnableOption "1Password";
  };

  config =
    let
      cfg = config.${namespace}.programs._1password;
    in
    lib.mkIf cfg.enable {
      home.packages = with pkgs; [
        _1password-cli
        _1password-gui
      ];
    };
}
