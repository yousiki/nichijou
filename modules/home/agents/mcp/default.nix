{pkgs, ...}: {
  programs.mcp = {
    enable = true;
    servers = {
      context7 = {
        url = "https://mcp.context7.com/mcp";
      };
      astro-docs = {
        url = "https://mcp.docs.astro.build/mcp";
      };
      nixos = {
        command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
      };
    };
  };
}
