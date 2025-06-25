# Configuration for Mio (Macbook Air with M4 chip)
_: {
  imports = [
    ./homebrew-casks.nix
  ];

  nichijou = {
    homebrew = {
      enable = true;
      enableMirror = true;
    };
  };

  networking = {
    computerName = "YouSiki's Mio";
    hostName = "mio";
  };
}
