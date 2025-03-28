{
  channels,
  inputs,
  self,
  ...
}: let
  treefmtEval = inputs.treefmt-nix.lib.evalModule channels.nixpkgs "${self}/treefmt.nix";
in
  treefmtEval.config.build.wrapper
