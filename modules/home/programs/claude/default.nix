{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.claude = {
    enable = lib.mkEnableOption "Claude";
  };

  config = lib.mkIf config.${namespace}.programs.claude.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isDarwin;
        message = "Claude is only supported on macOS.";
      }
    ];

    home.packages = [ pkgs.brewCasks.claude ];
  };
}
