{
  config,
  lib,
  namespace,
  ...
}:
{
  options.${namespace}.programs.yazi = {
    enable = lib.mkEnableOption "yazi";
  };

  config = lib.mkIf config.${namespace}.programs.yazi.enable {
    programs.yazi = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
