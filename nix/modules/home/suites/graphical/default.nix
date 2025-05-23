{
  lib,
  namespace,
  config,
  ...
}:
let
  cfg = config.${namespace}.suites.graphical;
in
{
  options.${namespace}.suites.graphical = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable graphical suite.";
    };
  };

  config = lib.mkIf cfg.enable {
    ${namespace} = {
      programs = {
        _1password.enable = true;
        firefox.enable = true;
        google-chrome.enable = true;
        kitty.enable = true;
        vscode.enable = true;
        zed-editor.enable = false;
      };
    };
  };
}
