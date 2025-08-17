{
  config,
  lib,
  namespace,
  ...
}:
{
  options.${namespace}.programs.direnv = {
    enable = lib.mkEnableOption "direnv";
  };

  config = lib.mkIf config.${namespace}.programs.direnv.enable {
    programs.direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };
  };
}
