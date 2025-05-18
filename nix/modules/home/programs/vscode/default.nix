{
  lib,
  namespace,
  config,
  ...
}:
let
  cfg = config.${namespace}.programs.vscode;
in
{
  options.${namespace}.programs.vscode = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable Visual Studio Code.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.vscode = {
      enable = true;
      mutableExtensionsDir = true;
    };
  };
}
