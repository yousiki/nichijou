{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.easydict = {
    enable = lib.mkEnableOption "Easydict";
  };

  config =
    let
      cfg = config.${namespace}.programs.easydict;
    in
    lib.mkIf cfg.enable {
      home.packages = [
        pkgs.${namespace}.easydict
      ];
    };
}
