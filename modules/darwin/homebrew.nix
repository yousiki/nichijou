{
  lib,
  pkgs,
  ...
}:
{
  homebrew = {
    # Enable Homebrew.
    enable = true;
    # Disable automatic updates, upgrades, and cleanup.
    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "none";
    };
    # Add homebrew taps.
    taps = [
      "buo/cask-upgrade"
    ];
  };

  # Add `/opt/homebrew/bin` to PATH on Apple silicon (aarch64-darwin) hosts.
  environment.systemPath = lib.optional (pkgs.system == "aarch64-darwin") "/opt/homebrew/bin";
}
