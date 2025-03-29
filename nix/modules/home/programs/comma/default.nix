{
  lib,
  pkgs,
  namespace,
  config,
  ...
}:
let
  cfg = config.${namespace}.programs.comma;
in
{
  options.${namespace}.programs.comma = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable comma.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs = {
      nix-index-database.comma.enable = true;

      nix-index = {
        enable = true;
        package = pkgs.nix-index;

        enableBashIntegration = true;
        enableFishIntegration = true;
        enableZshIntegration = true;

        # Symlink nix-index-database to ~/.cache/nix-index
        symlinkToCacheHome = true;
      };
    };
  };
}
