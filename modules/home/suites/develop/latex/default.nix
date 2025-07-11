{
  config,
  lib,
  namespace,
  ...
}:
{
  options.${namespace}.suites.develop.latex = {
    enable = lib.mkEnableOption "Develop LaTeX Language Suite";
  };

  config =
    let
      cfg = config.${namespace}.suites.develop.latex;
    in
    lib.mkIf cfg.enable {
      nichijou.programs = {
        texlive.enable = true;
      };
    };
}
