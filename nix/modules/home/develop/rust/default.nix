{
  lib,
  pkgs,
  namespace,
  config,
  ...
}:
let
  cfg = config.${namespace}.develop.rust;
in
{
  options.${namespace}.develop.rust = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable rust programming language support.";
    };
  };

  config = lib.mkIf cfg.enable {
    home = {
      # Install required packages.
      packages = with pkgs; [ rustup ];

      # Add cargo path to PATH.
      sessionPath = [ "$HOME/.cargo/bin" ];

      # Configure cargo.
      file = {
        ".cargo/config.toml".source = ./config.toml;
      };
    };
  };
}
