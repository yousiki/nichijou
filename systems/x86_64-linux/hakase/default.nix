_: {
  imports = [
    ./desktop.nix
    ./filesys.nix
    ./settings.nix
  ];

  nichijou = {
    clash.enable = true;
    fonts.enable = true;
    nvidia.enable = true;
    tailscale.enable = true;
    virtualisation.enable = true;
  };
}
