{
  config,
  lib,
  namespace,
  ...
}:
{
  options.${namespace}.programs.thunderbird = {
    enable = lib.mkEnableOption "Thunderbird";
  };

  config =
    let
      cfg = config.${namespace}.programs.thunderbird;
    in
    lib.mkIf cfg.enable {
      programs.thunderbird = {
        enable = true;
        profiles.default = {
          isDefault = true;
          settings = { };
        };
      };
    };
}
