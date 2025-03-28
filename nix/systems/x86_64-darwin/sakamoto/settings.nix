# System settings for Darwin host sakamoto.
_: {
  # Set the hostname and computer name
  networking = {
    hostName = "sakamoto"; # The hostname of the system
    computerName = "YouSiki's Macbook Pro"; # The name displayed in the network and system settings
  };

  # Add ability to use TouchID for sudo authentication
  security.pam.services.sudo_local.touchIdAuth = true; # Enable TouchID for sudo authentication

  # System configurations
  system.defaults = {
    NSGlobalDomain = {
      ApplePressAndHoldEnabled = false; # Disable press-and-hold for keys in favor of key repeat
      AppleShowAllExtensions = true; # Show all file extensions in Finder
    };
    dock = {
      show-recents = false; # Hide recent applications in the Dock
      tilesize = 48; # Set the Dock icon size to 48 pixels
    };
    finder = {
      QuitMenuItem = true; # Enable the Quit option in Finder's menu
      ShowPathbar = true; # Show the path bar at the bottom of Finder windows
      ShowStatusBar = true; # Show the status bar at the bottom of Finder windows
    };
    trackpad = {
      Clicking = true; # Enable tap-to-click on the trackpad
      TrackpadThreeFingerDrag = true; # Enable three-finger drag gesture on the trackpad
    };
  };
}
