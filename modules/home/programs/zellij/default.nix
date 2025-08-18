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

  config = lib.mkIf config.${namespace}.programs.zellij.enable {
    programs.zellij = {
      enable = true;
      settings = {
        show_startup_tips = false;
        show_release_notes = false;
      };
    };
  };
}
