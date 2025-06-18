{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.google-chrome = {
    enable = lib.mkEnableOption "Google Chrome";
    enableAlias = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable alias for google-chrome-stable.";
    };
  };

  config =
    let
      cfg = config.${namespace}.programs.google-chrome;
    in
    lib.mkIf cfg.enable {
      home = {
        packages = with pkgs; [
          google-chrome
        ];
        shellAliases = lib.mkIf cfg.enableAlias {
          chrome = "google-chrome-stable";
          google-chrome = "google-chrome-stable";
        };
      };
    };
}
