# System configurations that applied to all nix-darwin systems
{ inputs, ... }:
{
  system = {
    configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
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
    primaryUser = "yousiki";
    stateVersion = 6;
  };
}
