{
  config,
  lib,
  namespace,
  pkgs,
  ...
}: let
  cfg = config.${namespace}.develop.javascript;
in {
  options.${namespace}.develop.javascript = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable javascript programming language support.";
    };
  };

  config = lib.mkIf cfg.enable {
    home = {
      # Install required packages.
      packages = with pkgs; [
        bun
        deno
        nodejs
        pnpm
        typescript
        yarn-berry
      ];

      # Configure npm and pnpm.
      file = {
        ".npmrc".source = ./.npmrc;
      };
    };
  };
}
