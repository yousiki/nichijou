{ inputs, nixosConfigurations, ... }:
{
  hostname = "hakase.siki.moe";
  sshOpts = [
    "-p"
    "22"
  ];
  autoRollback = true;
  fastConnection = true;
  interactiveSudo = true;
  magicRollback = true;
  remoteBuild = true;
  profiles.system = {
    sshUser = "yousiki";
    user = "yousiki";
    path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos nixosConfigurations.hakase;
    profilePath = "/home/yousiki/.local/state/nix/profiles/system";
  };
}
