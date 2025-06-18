{
  config,
  lib,
  namespace,
  ...
}:
{
  options.${namespace}.programs.bottom = {
    enable = lib.mkEnableOption "bottom";
  };

  config =
    let
      cfg = config.${namespace}.programs.bottom;
    in
    lib.mkIf cfg.enable {
      programs.bottom = {
        enable = true;
      };
    };
}
