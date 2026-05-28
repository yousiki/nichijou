{ pkgs, ... }:

{
  programs.bun = {
    enable = true;
    package = pkgs.bun;
  };

  home.packages = [
    pkgs.nodejs_24
    pkgs.rustup
  ];

  programs.uv = {
    enable = true;
    package = pkgs.uv;
  };
}
