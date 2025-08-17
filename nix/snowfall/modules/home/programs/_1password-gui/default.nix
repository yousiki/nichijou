{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs._1password-gui = {
    enable = lib.mkEnableOption "1Password GUI";
  };

  config = lib.mkIf config.${namespace}.programs._1password-gui.enable {
    home.packages = [ pkgs._1password-gui ];
  };
}
