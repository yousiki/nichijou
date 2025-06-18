{
  config,
  lib,
  namespace,
  ...
}:
{
  options.${namespace}.programs.helix = {
    enable = lib.mkEnableOption "helix editor";
  };

  config =
    let
      cfg = config.${namespace}.programs.helix;
    in
    lib.mkIf cfg.enable {
      programs.helix = {
        enable = true;
        defaultEditor = true;
      };
    };
}
