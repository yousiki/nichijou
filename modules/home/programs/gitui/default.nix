{
  config,
  lib,
  namespace,
  ...
}:
{
  options.${namespace}.programs.gitui = {
    enable = lib.mkEnableOption "gitui";
  };

  config =
    let
      cfg = config.${namespace}.programs.gitui;
    in
    lib.mkIf cfg.enable {
      programs.gitui = {
        enable = true;
      };
    };
}
