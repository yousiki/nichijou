# Secrets configuration for both NixOS and Darwin.
_: {
  # Configure sops for secrets management.
  sops = {
    defaultSopsFile = null;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };
}
