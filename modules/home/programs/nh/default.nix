{
  config,
  lib,
  namespace,
  ...
}:
{
  options.${namespace}.programs.nh = {
    enable = lib.mkEnableOption "nh";
  };

  config =
    let
      cfg = config.${namespace}.programs.nh;
    in
    lib.mkIf cfg.enable {
      programs.nh = {
        enable = true;
        flake = "${config.home.homeDirectory}/.nichijou";
        clean = {
          enable = true;
          dates = "weekly";
        };
      };
    };
}
