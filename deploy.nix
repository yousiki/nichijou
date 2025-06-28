# Use deploy-rs for multi-profile deployment
{ self, inputs }:
{
  nodes = {
    hakase = {
      hostname = "hakase";
      profiles.system = {
        user = "root";
        sshUser = "yousiki";
        path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.hakase;
        fastConnection = true;
        autoRollback = true;
        magicRollback = true;
        remoteBuild = true;
      };
    };

    yukko = {
      hostname = "yukko";
      profiles.system = {
        user = "root";
        sshUser = "yousiki";
        path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.yukko;
        fastConnection = false;
        autoRollback = true;
        magicRollback = true;
        remoteBuild = false;
      };
    };

    nano = {
      hostname = "nano";
      profiles.system = {
        user = "yousiki";
        sshUser = "yousiki";
        interactiveSudo = true;
        path = inputs.deploy-rs.lib.aarch64-darwin.activate.darwin self.darwinConfigurations.nano;
        fastConnection = true;
        autoRollback = true;
        magicRollback = true;
        remoteBuild = true;
      };
    };
  };
}
