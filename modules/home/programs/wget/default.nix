{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.wget = {
    enable = lib.mkEnableOption "wget";
  };

  config = lib.mkIf config.${namespace}.programs.wget.enable {
    home.packages = with pkgs; [ wget ];
  };
}
