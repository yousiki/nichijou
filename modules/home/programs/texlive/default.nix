{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.texlive = {
    enable = lib.mkEnableOption "TeX Live";
  };

  config =
    let
      cfg = config.${namespace}.programs.texlive;
    in
    lib.mkIf cfg.enable {
      home.packages = with pkgs; [
        tectonic
        texlive.combined.scheme-full
        texlivePackages.latexindent
      ];
    };
}
