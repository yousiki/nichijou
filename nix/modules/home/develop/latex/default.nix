# Home-manager module to enable LaTeX language support.
{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  cfg = config.${namespace}.develop.latex;
in
{
  options.${namespace}.develop.latex = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable LaTeX language support.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Install required packages.
    home.packages = with pkgs; [
      tex-fmt
      texlive.combined.scheme-full
    ];
  };
}
