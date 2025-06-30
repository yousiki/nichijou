{
  config,
  lib,
  namespace,
  ...
}:
{
  options.${namespace}.suites.develop.nix = {
    enable = lib.mkEnableOption "Develop Nix Language Suite";
  };

  config =
    let
      cfg = config.${namespace}.suites.develop.nix;
    in
    lib.mkIf cfg.enable {
      nichijou.programs = {
        nil.enable = true;
        nixd.enable = true;
        nixfmt.enable = true;
      };
    };
}
