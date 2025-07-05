# Use deploy-rs for multi-profile deployment
{ self, inputs, ... }:
{
  nodes = {
    hakase = {
      hostname = "hakase-ts";
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
      hostname = "yukko-ts";
      profiles.system = {
        user = "root";
        sshUser = "yousiki";
        path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.yukko;
        fastConnection = false;
        autoRollback = true;
        magicRollback = true;
        remoteBuild = true;
      };
    };

    nano = {
      hostname = "nano-ts";
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

    mio = {
      hostname = "mio-ts";
      profiles.system = {
        user = "yousiki";
        sshUser = "yousiki";
        interactiveSudo = true;
        path = inputs.deploy-rs.lib.aarch64-darwin.activate.darwin self.darwinConfigurations.mio;
        fastConnection = true;
        autoRollback = true;
        magicRollback = true;
        remoteBuild = true;
      };
    };
  };
}
