{ pkgs, ... }:
{
  home.packages = with pkgs; [
    basedpyright
    python3
    ruff
    ty
    uv
  ];
}
