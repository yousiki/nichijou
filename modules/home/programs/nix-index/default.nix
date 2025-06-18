{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:

{
  options.${namespace}.programs.nix-index = {
    enable = lib.mkEnableOption "nix-index";
  };

  config =
    let
      cfg = config.${namespace}.programs.nix-index;
    in
    lib.mkIf cfg.enable {
      programs.nix-index = {
        enable = true;
        enableBashIntegration = true;
        enableFishIntegration = true;
        enableZshIntegration = true;
        symlinkToCacheHome = true; # Symlink nix-index-database to ~/.cache/nix-index
      };
      home.packages = with pkgs; [
        comma
      ];
    };
}
