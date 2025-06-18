# Use treefmt-nix for code formatting
{ channels, inputs, ... }:
let
  treefmtConfig = _: {
    projectRootFile = "flake.nix";
    programs = {
      deadnix.enable = true;
      nixfmt.enable = true;
      statix.enable = true;
      stylua.enable = true;
    };
    settings.formatter =
      let
        commonExcludes = [
          "^.*\/[^\/\.]+$"
          "secrets/*"
          "static/*"
        ];
      in
      {
        deadnix.excludes = commonExcludes;
        nixfmt.excludes = commonExcludes;
        statix.excludes = commonExcludes;
        stylua.excludes = commonExcludes;
      };
  };

  treefmtEval = inputs.treefmt-nix.lib.evalModule channels.nixpkgs treefmtConfig;
in
treefmtEval.config.build.wrapper
