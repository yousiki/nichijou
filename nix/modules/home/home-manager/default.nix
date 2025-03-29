# Home-manager configurations.
{
  config,
  lib,
  ...
}:
{
  # Enable home-manager.
  programs.home-manager.enable = true;

  # Enable management of XDG base directories.
  xdg.enable = true;

  # Enable common shells and let home-manager manage.
  programs = {
    bash.enable = lib.mkDefault true;
    fish.enable = lib.mkDefault true;
    zsh.enable = lib.mkDefault true;
  };

  # Add custom paths to the session PATH.
  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
  ];

  # Set home-manager state version.
  home.stateVersion = "24.11";

  # TODO: Remove after upgrading to home-manager 25.05
  home.enableNixpkgsReleaseCheck = false;
}
