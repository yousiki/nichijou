{
  pkgs,
  ...
}:
{
  projectRootFile = "flake.nix";
  programs = {
    nixfmt = {
      enable = true;
      package = pkgs.nixfmt-rfc-style;
    };
    deadnix.enable = true;
    statix.enable = true;
  };
}
