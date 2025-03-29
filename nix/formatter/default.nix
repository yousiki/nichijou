{ channels, inputs, ... }:
let
  treefmtEval = inputs.treefmt-nix.lib.evalModule channels.nixpkgs ./treefmt.nix;
in
treefmtEval.config.build.wrapper
