{inputs, ...}: {
  imports = [
    inputs.catppuccin.homeModules.catppuccin
    inputs.nix-index-database.homeModules.nix-index
  ];

  home.enableNixpkgsReleaseCheck = false;
  home.preferXdgDirectories = true;

  xdg.enable = true;

  catppuccin = {
    autoEnable = true;
    enable = true;
    flavor = "mocha";
  };

  programs.home-manager.enable = true;

  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.nix-index-database.comma.enable = true;
}
