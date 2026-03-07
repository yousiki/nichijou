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
      # Up-to-date Codex package
      flake.inputs.codex-cli-nix.overlays.default
      # Up-to-date OpenCode package
      flake.inputs.opencode.overlays.default
      # Up-to-date MCP for NixOS package
      flake.inputs.mcp-nixos.overlays.default
    ];
  };
}
