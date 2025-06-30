{
  config,
  lib,
  namespace,
  ...
}:
{
  options.${namespace}.suites.develop.python = {
    enable = lib.mkEnableOption "Develop Python Language Suite";
  };

  config =
    let
      cfg = config.${namespace}.suites.develop.python;
    in
    lib.mkIf cfg.enable {
      nichijou.programs = {
        ruff.enable = true;
        uv.enable = true;
      };
    };
}
