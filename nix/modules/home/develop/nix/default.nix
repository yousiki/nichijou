{
  lib,
  pkgs,
  namespace,
  config,
  ...
}:
let
  cfg = config.${namespace}.develop.nix;
in
{
  options.${namespace}.develop.nix = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable nix programming language support.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Install required packages.
    home.packages = with pkgs; [
      deadnix
      nil
      nixd
      nixfmt-rfc-style
      statix
    ];
  };
}
