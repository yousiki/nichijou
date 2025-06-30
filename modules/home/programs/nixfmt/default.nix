{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.nixfmt = {
    enable = lib.mkEnableOption "nixfmt";
  };

  config =
    let
      cfg = config.${namespace}.programs.nixfmt;
    in
    lib.mkIf cfg.enable {
      home.packages = with pkgs; [
        nixfmt-rfc-style
      ];
    };
}
