{
  inputs,
  pkgs,
  ...
}: let
  treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
  wrapper = treefmtEval.config.build.wrapper;
in
  wrapper
  // {
    passthru =
      (wrapper.passthru or {})
      // {
        tests.check = treefmtEval.config.build.check ./..;
      };
  }
