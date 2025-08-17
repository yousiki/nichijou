{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.thunderbird = {
    enable = lib.mkEnableOption "Thunderbird";
  };

  config = lib.mkIf config.${namespace}.programs.thunderbird.enable {
    home.packages = [ pkgs.thunderbird ];
  };
}
