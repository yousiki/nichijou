{
  config,
  lib,
  namespace,
  ...
}:
{
  options.${namespace}.programs.direnv = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable direnv.";
    };
  };

  config =
    let
      cfg = config.${namespace}.programs.direnv;
    in
    lib.mkIf cfg.enable {
      programs.direnv = {
        enable = true;
        enableBashIntegration = true;
        enableFishIntegration = true;
        enableNushellIntegration = true;
        enableZshIntegration = true;
        nix-direnv.enable = true;
      };
    };
}
