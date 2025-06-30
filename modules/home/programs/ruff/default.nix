{
  config,
  lib,
  namespace,
  ...
}:
{
  options.${namespace}.programs.ruff = {
    enable = lib.mkEnableOption "ruff";
  };

  config =
    let
      cfg = config.${namespace}.programs.ruff;
    in
    lib.mkIf cfg.enable {
      programs.ruff = {
        enable = true;
        settings = {
          indent-width = 2;
          select = [ "I" ];
        };
      };
    };
}
