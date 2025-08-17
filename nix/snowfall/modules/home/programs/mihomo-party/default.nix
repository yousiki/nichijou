{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.mihomo-party = {
    enable = lib.mkEnableOption "Mihomo Party";
  };

  config =
    let
      mihomo-party =
        with pkgs;
        if stdenv.hostPlatform.isDarwin then brewCasks.mihomo-party else mihomo-party;
    in
    lib.mkIf config.${namespace}.programs.mihomo-party.enable {
      home.packages = [ mihomo-party ];
    };
}
