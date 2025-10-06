{
  self,
  ...
}:
{
  imports = [
    self.inputs.home-manager.darwinModules.default
  ];

  home-manager = {
    backupFileExtension = "bak";
    useGlobalPkgs = true;
    extraSpecialArgs = {
      inherit self;
    };
  };
}
