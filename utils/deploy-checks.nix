{
  channels,
  inputs,
  self,
  ...
}:
{
  checks = inputs.deploy-rs.lib.${channels.nixpkgs.system}.deployChecks self.deploy;
}
