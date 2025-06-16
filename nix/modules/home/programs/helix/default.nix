{
  lib,
  namespace,
  config,
  ...
}:
let
  cfg = config.${namespace}.programs.helix;
in
{
  options.${namespace}.programs.helix = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable helix.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.helix = {
      enable = true;
      defaultEditor = true;
      settings = {
        editor = {
          lsp.display-messages = true;
        };
      };
    };
  };
}
