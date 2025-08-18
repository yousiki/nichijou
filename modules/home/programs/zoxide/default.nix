{
  config,
  lib,
  namespace,
  ...
}:
{
  options.${namespace}.programs.zoxide = {
    enable = lib.mkEnableOption "zoxide";
  };

  config = lib.mkIf config.${namespace}.programs.zoxide.enable {
    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
