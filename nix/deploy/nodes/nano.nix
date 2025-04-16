{ inputs, darwinConfigurations, ... }:
{
  hostname = "nano.siki.moe";
  sshOpts = [
    "-p"
    "12022"
  ];
  autoRollback = true;
  fastConnection = true;
  interactiveSudo = true;
  magicRollback = true;
  remoteBuild = true;
  profiles.system = {
    sshUser = "yousiki";
    user = "yousiki";
    path = inputs.deploy-rs.lib.aarch64-darwin.activate.darwin darwinConfigurations.nano;
    profilePath = "/Users/yousiki/.local/state/nix/profiles/system";
  };
}
