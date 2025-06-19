# Use treefmt-nix for code formatting
{
  channels,
  inputs,
  ...
}:
let
  inherit (inputs.nixpkgs) lib;

  formatters = [
    "deadnix"
    "nixfmt"
    "prettier"
    "statix"
    "stylua"
  ];

  excludes = [
    "^.*\/[^\/\.]+$"
    "secrets/*"
    "static/*"
  ];

  treefmtConfig = _: {
    projectRootFile = "flake.nix";
    programs = lib.genAttrs formatters (_name: {
      enable = true;
    });
    settings.formatter = lib.genAttrs formatters (_name: {
      inherit excludes;
    });
  };

  treefmtEval = inputs.treefmt-nix.lib.evalModule channels.nixpkgs treefmtConfig;
in
treefmtEval.config.build.wrapper
