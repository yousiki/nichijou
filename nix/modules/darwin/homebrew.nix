{ config, inputs, ... }:

{
  imports = [
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];

  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = config.system.primaryUser;
    autoMigrate = true;
    mutableTaps = false;

    taps = {
      "aprilnea/homebrew-tap" = inputs.aprilnea-homebrew-tap;
      "buo/homebrew-cask-upgrade" = inputs.buo-homebrew-cask-upgrade;
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
    };
  };

  homebrew = {
    enable = true;
    taps = builtins.attrNames config.nix-homebrew.taps;
    greedyCasks = true;

    onActivation = {
      autoUpdate = false;
      upgrade = true;
      cleanup = "none";
    };

    global = {
      autoUpdate = false;
      brewfile = true;
    };

    casks = [
      "1password"
      "aprilnea/tap/openlogi"
      "cloudflare-warp"
      "element"
    ];
    brews = [ ];
  };
}
