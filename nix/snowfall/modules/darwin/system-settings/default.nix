# System settings for all darwin systems.
# Graphical settings are applied to desktop systems only (tagged with "desktop").
{
  config,
  lib,
  namespace,
  ...
}:
{
  system.primaryUser = "yousiki";

  system.defaults =
    let
      isDesktop = builtins.elem "desktop" config.${namespace}.tags;
    in
    lib.optionalAttrs isDesktop {
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
}
