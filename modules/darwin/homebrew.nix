{
  flake,
  config,
  ...
}: let
  inherit (flake) inputs;
in {
  imports = [
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];

  # Manage Homebrew installation itself via nix-homebrew
  nix-homebrew = {
    enable = true;
    # User owning the Homebrew prefix — follows system.primaryUser
    user = config.system.primaryUser;
    # Apple Silicon: also install under the Intel prefix for Rosetta 2
    enableRosetta = true;
    # Migrate existing Homebrew installation to nix-homebrew management
    autoMigrate = true;
    # Allow imperative `brew tap` — practical for large taps like core/cask
    mutableTaps = true;
  };

  homebrew = {
    enable = true;

    onActivation = {
      cleanup = "none";
      autoUpdate = false;
      upgrade = false;
    };

    taps = [];
    brews = [];
    casks = [];
  };
}
