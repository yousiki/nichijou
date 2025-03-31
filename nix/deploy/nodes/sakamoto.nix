{ inputs, darwinConfigurations, ... }:
{
  hostname = "localhost";
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
    path = inputs.deploy-rs.lib.x86_64-darwin.activate.darwin darwinConfigurations.sakamoto;
    profilePath = "/Users/yousiki/.local/state/nix/profiles/system";
  };
}
