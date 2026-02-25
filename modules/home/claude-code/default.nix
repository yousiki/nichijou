{
  pkgs,
  lib,
  flake,
  ...
}: let
  selfPackages = flake.inputs.self.packages.${pkgs.system};

  plugins = [
    selfPackages.claude-code-plugin-astral
    selfPackages.claude-code-plugin-context7
    selfPackages.claude-code-plugin-superpowers
  ];

  basePackage = pkgs.claude-code;

  pluginArgs = lib.concatMapStringsSep " " (p: ''--add-flags "--plugin-dir ${p}"'') plugins;

  wrappedPackage = pkgs.symlinkJoin {
    name = "${basePackage.name}-with-plugins";
    paths = [basePackage];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/claude ${pluginArgs}
    '';
  };
in {
  programs.claude-code = {
    enable = true;
    package = wrappedPackage;
    mcpServers = {
      nixos = {
        type = "stdio";
        command = lib.getExe flake.inputs.mcp-nixos.packages.${pkgs.system}.mcp-nixos;
        args = [];
      };
    };
    settings = {
      env = {
        CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
      };
    };
  };
}
