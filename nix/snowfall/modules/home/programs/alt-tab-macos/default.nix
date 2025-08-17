{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.alt-tab-macos = {
    enable = lib.mkEnableOption "Alt-Tab";
  };

  config = lib.mkIf config.${namespace}.programs.alt-tab-macos.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isDarwin;
        message = "Alt-Tab is only supported on macOS.";
      }
    ];

    home.packages = [ pkgs.alt-tab-macos ];
  };
}
