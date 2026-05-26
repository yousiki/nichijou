{ flake, ... }:

{
  imports = [
    flake.homeModules.common
    flake.homeModules.cli
    flake.homeModules.desktop
  ];

  home.stateVersion = "26.05";
}
