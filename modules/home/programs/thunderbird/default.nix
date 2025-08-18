{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.thunderbird = {
    enable = lib.mkEnableOption "Thunderbird";
  };

  config = lib.mkIf config.${namespace}.programs.thunderbird.enable {
    home.packages =
      let
        thunderbird =
          with pkgs;
          if stdenv.hostPlatform.isDarwin then brewCasks.thunderbird else thunderbird;
      in
      [ thunderbird ];
  };
}
