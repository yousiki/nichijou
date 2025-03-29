{
  lib,
  namespace,
  config,
  ...
}:
let
  cfg = config.${namespace}.suites.develop;
in
{
  options.${namespace}.suites.develop = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable develop suite.";
    };
  };

  config = lib.mkIf cfg.enable {
    ${namespace}.develop = {
      cxx.enable = true;
      javascript.enable = true;
      nix.enable = true;
      python.enable = true;
      rust.enable = true;
    };
  };
}
