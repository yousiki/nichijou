{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.gemini-cli = {
    enable = lib.mkEnableOption "gemini-cli";
  };

  config =
    let
      cfg = config.${namespace}.programs.gemini-cli;
    in
    lib.mkIf cfg.enable {
      home.packages = with pkgs; [ gemini-cli ];
    };
}
