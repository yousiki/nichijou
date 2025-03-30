{ self, inputs, ... }:
{
  nodes = inputs.haumea.lib.load {
    src = ./nodes;
    inputs = {
      inherit inputs;
      inherit (self) nixosConfigurations darwinConfigurations;
    };
  };
}
