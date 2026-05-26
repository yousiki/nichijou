{ flake, ... }:

{
  imports = [
    flake.homeModules.common
    flake.homeModules.cli
  ];

  home.stateVersion = "26.05";
}
