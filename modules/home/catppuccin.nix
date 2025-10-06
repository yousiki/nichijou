{ self, ... }:
{
  imports = [
    self.inputs.catppuccin.homeModules.catppuccin
  ];

  catppuccin.enable = true;
}
