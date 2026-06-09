{
  config,
  pkgs,
  ...
}: let
  bunInstall = "${config.home.homeDirectory}/.bun";
in {
  programs.bun = {
    enable = true;
    package = pkgs.bun;
  };

  home.sessionVariables = {
    BUN_INSTALL = bunInstall;
  };

  home.sessionPath = [
    "${bunInstall}/bin"
  ];

  home.packages = [
    pkgs.nodejs_24
    pkgs.rustup
  ];

  programs.uv = {
    enable = true;
    package = pkgs.uv;
  };
}
