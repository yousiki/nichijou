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

  config = lib.mkIf config.${namespace}.programs.nix-index.enable {
    programs.nix-index = {
      enable = true;
      enableZshIntegration = true;
      symlinkToCacheHome = true; # Symlink nix-index-database to ~/.cache/nix-index
    };
    home.packages = with pkgs; [
      comma
    ];
  };
}
