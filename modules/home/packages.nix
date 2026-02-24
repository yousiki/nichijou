{
  pkgs,
  lib,
  flake,
  ...
}: {
  # Nix packages to install to $HOME
  #
  # Search for packages here: https://search.nixos.org/packages
  home.packages =
    (with pkgs; [
      omnix

      # Unix tools
      ripgrep # Better `grep`
      fd
      sd
      tree
      gnumake

      # File transfer
      rsync

      # Disk tools
      duf # Disk usage summary
      gdu # Interactive disk usage

      # On ubuntu, we need this less for `man home-configuration.nix`'s pager to work.
      less
    ])
    # macOS-only packages
    ++ lib.optionals pkgs.stdenv.isDarwin [
      flake.inputs.self.packages.${pkgs.system}.mole
    ];

  # Programs natively supported by home-manager.
  # They can be configured in `programs.*` instead of using home.packages.
  programs = {
    # Better `cat`
    bat.enable = true;
    jq.enable = true;
    # System resource monitor
    btop.enable = true;
    # Tmate terminal sharing.
    tmate = {
      enable = true;
    };
    # Terminal multiplexers
    tmux.enable = true;
    zellij.enable = true;
    # Terminal file manager
    yazi = {
      enable = true;
      enableZshIntegration = true;
    };
    # Nix helper — set NH_FLAKE or programs.nh.flake to point at your config
    nh.enable = true;
  };
}
