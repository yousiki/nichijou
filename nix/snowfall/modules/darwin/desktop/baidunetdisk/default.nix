# Install Baidu Netdisk for desktops.
{
  config,
  lib,
  namespace,
  ...
}:
lib.mkIf (builtins.elem "desktop" config.${namespace}.tags) {
  homebrew.casks = [
    "baidunetdisk"
  ];
}
