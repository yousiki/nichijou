{
  pkgs,
  lib,
  ...
}: {
  # Shared MCP servers. Consumers opt in with `enableMcpIntegration` and each
  # Home Manager module translates this canonical shape into its own config.
  programs.mcp = {
    enable = true;

    servers = {
      context7.url = "https://mcp.context7.com/mcp";
      deepwiki.url = "https://mcp.deepwiki.com/mcp";
      nixos.command = lib.getExe pkgs.mcp-nixos;
    };
  };
}
