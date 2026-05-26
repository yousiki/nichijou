{ inputs, ... }:

{
  imports = [
    inputs.catppuccin.homeModules.catppuccin
  ];

  home.enableNixpkgsReleaseCheck = false;

  catppuccin = {
    enable = true;
    flavor = "mocha";

    # Starship imports a generated Catppuccin TOML file during evaluation.
    starship.enable = false;
  };

  programs.home-manager.enable = true;
}
