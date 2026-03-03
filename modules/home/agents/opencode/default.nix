{
  pkgs,
  flake,
  ...
}: let
  selfPackages = flake.inputs.self.packages.${pkgs.system};
in {
  programs.opencode = {
    enable = true;
    package = selfPackages.opencode;
    enableMcpIntegration = true;
    settings = {
      plugin = [
        "oh-my-opencode@latest"
      ];
    };
  };

  xdg.configFile."opencode/oh-my-opencode.json".source = ./oh-my-opencode.json;
}
