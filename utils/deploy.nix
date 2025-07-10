# Use deploy-rs for multi-profile deployment
{ self, inputs, ... }:
{
  nodes = rec {
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

    hakase-ts = hakase // {
      hostname = "hakase-ts";
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
        remoteBuild = true;
      };
    };

    yukko-ts = yukko // {
      hostname = "yukko-ts";
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

    nano-ts = nano // {
      hostname = "nano-ts";
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

    mio-ts = mio // {
      hostname = "mio-ts";
    };
  };
}
