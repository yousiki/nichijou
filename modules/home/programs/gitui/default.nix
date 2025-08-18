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

  config = lib.mkIf config.${namespace}.programs.gitui.enable {
    programs.gitui = {
      enable = true;
    };
  };
}
