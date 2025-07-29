# Install Mihomo-Party for desktops.
{
  config,
  lib,
  namespace,
  ...
}:
lib.mkIf (builtins.elem "desktop" config.${namespace}.tags) {
  homebrew = {
    taps = [
      "mihomo-party-org/mihomo-party"
    ];
    casks = [
      "mihomo-party"
    ];
  };
}
