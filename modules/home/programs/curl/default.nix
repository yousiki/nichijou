{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.curl = {
    enable = lib.mkEnableOption "curl";
  };

  config = lib.mkIf config.${namespace}.programs.curl.enable {
    home.packages = with pkgs; [ curl ];
  };
}
