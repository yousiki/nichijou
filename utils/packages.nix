{
  channels,
  inputs,
  ...
}:
{
  packages = {
    deploy-rs = inputs.deploy-rs.packages.${channels.nixpkgs.system}.default;
    sops = inputs.sops-nix.packages.${channels.nixpkgs.system}.default;
  };
}
