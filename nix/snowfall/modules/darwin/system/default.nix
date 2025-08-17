# System settings for all darwin systems.
_: {
  system = {
    primaryUser = "yousiki";

    defaults = {
      dock = {
        autohide = true;
        show-recents = false;
        tilesize = 32;
      };
      finder = {
        AppleShowAllExtensions = true;
        NewWindowTarget = "Home";
        QuitMenuItem = true;
        ShowPathbar = true;
        ShowStatusBar = true;
      };
      trackpad = {
        Clicking = true;
        TrackpadThreeFingerDrag = true;
      };
      NSGlobalDomain = {
        ApplePressAndHoldEnabled = false;
        AppleShowAllExtensions = true;
      };
    };
  };
}
