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
      "cloudflare-warp"
      "element"
    ];
    brews = [ ];
  };
}
