{
  config,
  lib,
  namespace,
  ...
}:
{
  options.${namespace}.programs.mihomo-party = {
    enable = lib.mkEnableOption "Mihomo Party";
  };

  config = lib.mkIf config.${namespace}.programs.mihomo-party.enable {
    # Mihomo Party must be installed via Homebrew
    assertions = [
      {
        assertion = config.homebrew.enable;
        message = "Mihomo Party requires Homebrew to install";
      }
    ];

    homebrew.casks = [ "mihomo-party" ];
  };
}
