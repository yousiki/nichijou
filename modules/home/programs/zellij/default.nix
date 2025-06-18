{
  config,
  lib,
  namespace,
  ...
}:
{
  options.${namespace}.programs.zellij = {
    enable = lib.mkEnableOption "zellij";
  };

  config =
    let
      cfg = config.${namespace}.programs.zellij;
    in
    lib.mkIf cfg.enable {
      programs.zellij = {
        enable = true;
        settings = {
          show_startup_tips = false;
          show_release_notes = false;
        };
      };
    };
}
