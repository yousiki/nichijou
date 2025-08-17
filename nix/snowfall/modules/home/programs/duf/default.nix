{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.duf = {
    enable = lib.mkEnableOption "duf";
  };

  config = lib.mkIf config.${namespace}.programs.duf.enable {
    home.packages = with pkgs; [ duf ];
  };
}
