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
    home.packages =
      let
        vscode = with pkgs; if stdenv.hostPlatform.isDarwin then brewCasks.visual-studio-code else vscode;
      in
      [ vscode ];
  };
}
