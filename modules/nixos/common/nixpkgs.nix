{flake, ...}: {
  nixpkgs = {
    config = {
      allowBroken = false;
      allowUnsupported = false;
      allowUnfree = true;
    };
    overlays = [
      # Up-to-date Claude Code package
      flake.inputs.claude-code.overlays.default
    ];
  };
}
