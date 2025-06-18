{
  config,
  lib,
  namespace,
  ...
}:
{
  options.${namespace}.programs.firefox = {
    enable = lib.mkEnableOption "Firefox";
  };

  config =
    let
      cfg = config.${namespace}.programs.firefox;
    in
    lib.mkIf cfg.enable {
      programs.firefox = {
        enable = true;
        languagePacks = [
          "zh-CN"
          "zh-TW"
        ];
      };
    };
}
