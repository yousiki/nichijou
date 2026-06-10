{
  config,
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  home.packages = [
    pkgs.age
    pkgs.sops
    pkgs.ssh-to-age
  ];

  home.sessionVariables = {
    CLIPROXYAPI_API_KEY_FILE = config.sops.secrets."cliproxyapi-api-key".path;
    CLIPROXYAPI_MANAGEMENT_KEY_FILE = config.sops.secrets."cliproxyapi-management-key".path;
  };

  sops = {
    defaultSopsFile = ../../../secrets/sakurai-yousiki.yaml;
    defaultSopsFormat = "yaml";

    age.sshKeyPaths = [
      "${config.home.homeDirectory}/.ssh/id_ed25519"
    ];

    secrets = {
      "cliproxyapi-api-key" = {
        mode = "0400";
      };

      "cliproxyapi-management-key" = {
        mode = "0400";
      };
    };
  };
}
