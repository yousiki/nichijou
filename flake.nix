{
  description = "Personal NixOS/Nix-Darwin/Home-Manager Configurations";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # macOS system configuration
    nix-darwin.url = "github:nix-darwin/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    # User environment management
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Flake framework
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixos-unified.url = "github:srid/nixos-unified";

    # Formatter
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    # nix-index database for command-not-found
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    # Neovim
    nixvim.url = "github:nix-community/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
    nixvim.inputs.flake-parts.follows = "flake-parts";

    # Homebrew management
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # Catppuccin theme
    catppuccin.url = "github:catppuccin/nix";

    # Claude Code
    claude-code.url = "github:sadjow/claude-code-nix";

    # Secrets management
    sops-nix.url = "github:mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    # MCP server for NixOS/HomeManager/nix-darwin
    mcp-nixos.url = "github:utensils/mcp-nixos";
  };

  # Wired using https://nixos-unified.org/guide/autowiring
  outputs = inputs:
    inputs.nixos-unified.lib.mkFlake {
      inherit inputs;
      root = ./.;
    };
}
