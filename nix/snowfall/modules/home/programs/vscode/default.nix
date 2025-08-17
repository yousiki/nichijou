{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.vscode = {
    enable = lib.mkEnableOption "Visual Studio Code";
  };

  config = lib.mkIf config.${namespace}.programs.vscode.enable {
    home.packages = [ pkgs.vscode ];
  };
}
