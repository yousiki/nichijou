{
  pkgs,
  lib,
  flake,
  ...
}: let
  selfPackages = flake.inputs.self.packages.${pkgs.system};

  plugins = [
    selfPackages.claude-code-plugin-superpowers
    selfPackages.claude-code-plugin-astral
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
    settings = {
      env = {
        CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
      };
    };
  };
}
