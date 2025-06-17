# Home-manager configurations for all users
{ config, ... }:
{
  # Enable home-manager.
  programs.home-manager.enable = true;
  # Enable management of XDG base directories.
  xdg.enable = true;
  home = {
    # Add custom paths to the session PATH.
    sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];
    # Set home-manager state version.
    stateVersion = "25.05";
  };
}
