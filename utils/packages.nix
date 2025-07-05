{
  channels,
  inputs,
  ...
}:
{
  packages = {
    deploy-rs = inputs.deploy-rs.packages.${channels.nixpkgs.system}.default;
  };
}
