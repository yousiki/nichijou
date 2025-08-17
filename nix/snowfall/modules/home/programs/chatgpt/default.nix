{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.chatgpt = {
    enable = lib.mkEnableOption "ChatGPT";
  };

  config = lib.mkIf config.${namespace}.programs.chatgpt.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isDarwin;
        message = "ChatGPT is only supported on macOS.";
      }
    ];

    home.packages = [ pkgs.brewCasks.chatgpt ];
  };
}
