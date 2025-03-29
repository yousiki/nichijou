# Secrets configuration for both NixOS and Darwin.
{ lib, pkgs, ... }:
{
  # Configure sops for secrets management.
  sops = {
    defaultSopsFile = null;
    age = {
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    };
    secrets = {
      # Clash configuration file.
      "clash.yaml" = {
        sopsFile = lib.snowfall.fs.get-file "secrets/clash.yaml";
        key = "";
      };
      # Credentials for NAS MCK.
      "nas-mck-credentials.env" = {
        sopsFile = lib.snowfall.fs.get-file "secrets/nas-mck-credentials.env";
        format = "dotenv";
        key = "";
      };
      # Credentials for NAS YYP.
      "nas-yyp-credentials.env" = {
        sopsFile = lib.snowfall.fs.get-file "secrets/nas-yyp-credentials.env";
        format = "dotenv";
        key = "";
      };
      # Credentials for NAS satoshi.
      "nas-satoshi-credentials.env" = {
        sopsFile = lib.snowfall.fs.get-file "secrets/nas-satoshi-credentials.env";
        format = "dotenv";
        key = "";
      };
    };
  };

  # Install necessary packages for secrets management.
  environment.systemPackages = with pkgs; [
    age
    sops
    ssh-to-age
  ];
}
