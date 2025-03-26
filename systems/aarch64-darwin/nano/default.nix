{pkgs, ...}: {
  imports = [
    ./casks.nix
  ];

  # Set the hostname and computer name
  networking = {
    hostName = "nano";
    computerName = "YouSiki's Mac Mini";
  };

  # Add ability to use TouchID for sudo authentication
  security.pam.services.sudo_local.touchIdAuth = true;

  # System configurations
  system.defaults = {
    NSGlobalDomain = {
      ApplePressAndHoldEnabled = false;
      AppleShowAllExtensions = true;
    };
    dock = {
      show-recents = false;
      tilesize = 48;
    };
    finder = {
      QuitMenuItem = true;
      ShowPathbar = true;
      ShowStatusBar = true;
    };
    trackpad = {
      Clicking = true;
      TrackpadThreeFingerDrag = true;
    };
  };

  nichijou = {
    system = {
      homebrew.enable = true;
      secrets.enable = true;
    };
  };

  environment.systemPackages = with pkgs; [
    alejandra
    nodejs
  ];
}
