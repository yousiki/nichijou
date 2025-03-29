{
  lib,
  pkgs,
  namespace,
  config,
  ...
}:
let
  cfg = config.${namespace}.programs.nix-index;
in
{
  options.${namespace}.programs.nix-index = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable nix-index.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs = {
      nix-index-database.nix-index.enable = true;

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
