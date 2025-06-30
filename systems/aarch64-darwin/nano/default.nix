# Configuration for Mio (Macbook Air with M4 chip)
_: {
  imports = [
    ./homebrew-casks.nix
  ];

  nichijou = {
    fonts.enable = true;
    homebrew = {
      enable = true;
      enableMirror = true;
    };
    nix.enableMirror = true;
    shell.enable = true;
    sshkeys.enable = true;
    tailscale.enable = true;
  };

  networking = {
    computerName = "YouSiki's Nano";
    hostName = "nano";
  };
}
