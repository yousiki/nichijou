# sops-nix secret management
{
  config,
  flake,
  ...
}: let
  inherit (flake) inputs;
in {
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  sops = {
    age.sshKeyPaths = ["${config.home.homeDirectory}/.ssh/id_ed25519"];
  };
}
