# Basic shell environment
{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.shell = {
    enable = lib.mkEnableOption "Basic shell environment";
  };

  config = lib.mkIf config.${namespace}.shell.enable {
    programs = {
      fish.enable = true;
      tmux.enable = true;
      zsh.enable = true;
    };

    environment.systemPackages = with pkgs; [
      coreutils
      curl
      eza
      git
      unzip
      wget
      zoxide
    ];
  };
}
